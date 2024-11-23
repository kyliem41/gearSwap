import base64
import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime
import jwt
import requests
from jwt.algorithms import RSAAlgorithm
import boto3

MAX_FILE_SIZE = 5 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {
    'image/jpeg',
    'image/png'
}

def cors_response(status_code, body, content_type='application/json'):
    """Helper function to create responses with proper CORS headers"""
    headers = {
        'Content-Type': content_type,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE'
    }
    
    if content_type == 'application/json':
        body = json.dumps(body, default=str)
    
    return {
        'statusCode': status_code,
        'headers': headers,
        'body': body,
        'isBase64Encoded': content_type != 'application/json'
    }
    
def lambda_handler(event, context):
    if event['httpMethod'] == 'OPTIONS':
        return cors_response(200, {'message': 'OK'})
    
    http_method = event['httpMethod']
    resource_path = event['resource']
    
    try:
        auth_header = event.get('headers', {}).get('Authorization')
        if not auth_header:
            return cors_response(401, {'error': 'No authorization header'})

        # Extract token from Bearer authentication
        token = auth_header.split(' ')[-1]
        verify_token(token)
    except Exception as e:
        return cors_response(401, {'error': f'Authentication failed: {str(e)}'})

    if resource_path == '/userProfile/{Id}':
        if http_method == 'POST':
            return createProfile(event, context)
        elif http_method == 'GET':
            return getUserProfile(event, context)
        elif http_method == 'PUT':
            return putUserProfile(event, context)
        elif http_method == 'DELETE':
            return deleteUserProfile(event, context)
    elif resource_path == '/userProfile/{Id}/profilePicture':
        return updateProfilePicture(event, context)

    return cors_response (400, {'error': 'Unsupported route'})
    
########################
#AUTH
def verify_token(token):
    # Get the JWT token from the Authorization header
    if not token:
        raise Exception('No token provided')

    region = boto3.session.Session().region_name
    
    # Get the JWT kid (key ID)
    headers = jwt.get_unverified_header(token)
    kid = headers['kid']

    # Get the public keys from Cognito
    url = f'https://cognito-idp.{region}.amazonaws.com/{os.environ["COGNITO_USER_POOL_ID"]}/.well-known/jwks.json'
    response = requests.get(url)
    keys = response.json()['keys']

    # Find the correct public key
    public_key = None
    for key in keys:
        if key['kid'] == kid:
            public_key = RSAAlgorithm.from_jwk(json.dumps(key))
            break

    if not public_key:
        raise Exception('Public key not found')

    # Verify the token
    try:
        payload = jwt.decode(
            token,
            public_key,
            algorithms=['RS256'],
            audience=os.environ['COGNITO_CLIENT_ID'],
            options={"verify_exp": True}
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise Exception('Token has expired')
    except jwt.InvalidTokenError:
        raise Exception('Invalid token')

##############
def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} not serializable")

def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT'],
        
        connect_timeout=5
    )

#############
def createProfile(event, context):
    try:
        # Parse the request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = json.loads(event.get('body', '{}'))

        user_id = event['pathParameters']['Id']
        bio = body.get('bio')
        location = body.get('location')
        
        default_profile_picture = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQACWAJYAAD/4QAC/9sAQwADAgICAgIDAgICAwMDAwQGBAQEBAQIBgYFBgkICgoJCAkJCgwPDAoLDgsJCQ0RDQ4PEBAREAoMEhMSEBMPEBAQ/8IACwgHgAeAAQERAP/EAB4AAQACAgMBAQEAAAAAAAAAAAAICQYHBAUKAwIB/..."
        profilePicture = body.get('profilePicture', default_profile_picture)

    except json.JSONDecodeError:
        return cors_response(400, "Invalid JSON format in request body")

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Check if the user exists and get their username
                cursor.execute("SELECT username FROM users WHERE id = %s", (user_id,))
                user = cursor.fetchone()
                if not user:
                    return cors_response(404, "User not found")
                username = user['username']

                # Insert a new profile into the userProfile table
                insert_query = """
                INSERT INTO userProfile (userId, username, bio, location, profilePicture) 
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id, userId, username, bio, location, profilePicture;
                """
                cursor.execute(insert_query, (user_id, username, bio, location, profilePicture))
                new_profile = cursor.fetchone()

                # Update the profileInfo column in the users table with the new profile ID
                update_user_query = """
                UPDATE users
                SET profileInfo = %s
                WHERE id = %s;
                """
                cursor.execute(update_user_query, (new_profile['id'], user_id))

                # Commit both the insertion and the update
                conn.commit()

        return cors_response(201, {
            "message": "UserProfile created successfully and user profileInfo updated",
            "profile": new_profile
        })

    except psycopg2.IntegrityError as e:
        print(f"IntegrityError: {str(e)}")
        return cors_response(400, "UserProfile for this user already exists")
    except Exception as e:
        print(f"Failed to create profile. Error: {str(e)}")
        return cors_response(500, f"Error creating profile: {str(e)}")

################
def getUserProfile(event, context):
    user_id = event['pathParameters']['Id']

    get_query = """
    SELECT profilePicture, 
        content_type,
        bio, 
        location
    FROM userProfile
    WHERE userId = %s
    """
    
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(get_query, (user_id,))
                userProfile = cursor.fetchone()

        if userProfile:
            if userProfile['profilepicture'] is not None and userProfile['content_type'] is not None:
                try:
                    base64_str = base64.b64encode(userProfile['profilepicture']).decode('utf-8')
                    userProfile['profilepicture'] = f"data:{userProfile['content_type']};base64,{base64_str}"
                except Exception as e:
                    print(f"Error encoding profile picture: {e}")
                    userProfile['profilepicture'] = None

            return cors_response(200, {
                "message": "UserProfile retrieved successfully",
                "userProfile": userProfile
            })
        else:
            return cors_response(404, "UserProfile not found")
            
    except Exception as e:
        print(f"Error getting profile: {str(e)}")
        return cors_response(500, f"Error getting profile: {str(e)}")

############
def putUserProfile(event, context):
    try:
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = json.loads(event.get('body', '{}'))

        user_id = event['pathParameters']['Id']
        bio = body.get('bio')
        location = body.get('location')
        profilePicture = body.get('profilePicture')

    except json.JSONDecodeError:
        return cors_response(400, "Invalid JSON format in request body")

    update_query = """
    UPDATE userProfile    
    SET bio = COALESCE(%s, bio), 
        location = COALESCE(%s, location), 
        profilePicture = COALESCE(%s, profilePicture)
    WHERE userId = %s 
    RETURNING id, userId, bio, location, profilePicture;
    """
    
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                print("Executing update query")
                cursor.execute(update_query, (bio, location, profilePicture, user_id))
                updated_userProfile = cursor.fetchone()
                
                if updated_userProfile:
                    cursor.execute("SELECT username FROM users WHERE id = %s", (user_id,))
                    user = cursor.fetchone()
                    if user:
                        updated_userProfile['username'] = user['username']
                
                conn.commit()
        
        if updated_userProfile:
            return cors_response(200, {
                "message": "UserProfile updated successfully",
                "updated_userProfile": updated_userProfile
            })
        else:
            return cors_response(404, "UserProfile not found")
        
    except Exception as e:
        print(f"Failed to update UserProfile. Error: {str(e)}")
        print(f"Error type: {type(e)}")
        return cors_response(500, f"Error updating UserProfile: {str(e)}")

##########
def deleteUserProfile(event, context):
    try:
        user_id = event['pathParameters']['Id']
        
        delete_query = "DELETE FROM userProfile WHERE userId = %s RETURNING id;"

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(delete_query, (user_id,))
                deleted_userProfile = cursor.fetchone()
                conn.commit()
        
        if deleted_userProfile:
            return cors_response(200, {
                "message": "UserProfile deleted successfully",
                "deletedProfileId": deleted_userProfile['id']
            })

        else:
            return cors_response(404, "UserProfile not found")
        
    except Exception as e:
        print(f"Failed to delete UserProfile. Error: {str(e)}")
        return cors_response(500, f"Error deleting UserProfile: {str(e)}")
    
##########
# IMAGES
def updateProfilePicture(event, context):
    try:
        user_id = event['pathParameters']['Id']
        
        # Debug logging
        print("Event received:", json.dumps(event))
        
        # Get the raw body and handle possible encoding
        raw_body = event.get('body', '')
        if event.get('isBase64Encoded', False):
            try:
                raw_body = base64.b64decode(raw_body).decode('utf-8')
            except Exception as e:
                print(f"Base64 decode error for request body: {e}")
                return cors_response(400, {'error': 'Invalid base64 encoded request body'})

        # Parse JSON body with explicit error handling
        try:
            if isinstance(raw_body, str):
                body = json.loads(raw_body)
            else:
                return cors_response(400, {'error': 'Request body must be a string'})
        except json.JSONDecodeError as e:
            print(f"JSON decode error: {str(e)}")
            print(f"Raw body received: {raw_body[:200]}")
            return cors_response(400, {
                'error': 'Invalid JSON format in request body',
                'details': str(e),
                'body_preview': raw_body[:200]
            })

        # Validate required fields
        if 'profilePicture' not in body:
            return cors_response(400, {'error': 'Missing profilePicture field'})
        if 'content_type' not in body:
            return cors_response(400, {'error': 'Missing content_type field'})
            
        base64_data = str(body['profilePicture']).strip()
        content_type = str(body['content_type']).strip()

        # Validate content type
        if content_type not in ALLOWED_CONTENT_TYPES:
            return cors_response(400, {
                'error': 'Invalid content type',
                'allowed_types': list(ALLOWED_CONTENT_TYPES)
            })
        
        # Remove data URL prefix if present
        if base64_data.startswith('data:'):
            base64_data = base64_data.split(',')[1]

        # Decode base64 image data
        try:
            decoded_image = base64.b64decode(base64_data)
            if len(decoded_image) > MAX_FILE_SIZE:
                return cors_response(400, {
                    'error': 'Image size exceeds maximum allowed size',
                    'max_size_mb': MAX_FILE_SIZE / (1024 * 1024)
                })
        except Exception as e:
            print(f"Base64 decode error: {str(e)}")
            return cors_response(400, {'error': 'Invalid base64 image data'})

        # Update database
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # First update the profile
                update_query = """
                UPDATE userProfile
                SET profilePicture = %s,
                    content_type = %s
                WHERE userId = %s
                RETURNING id, userId, bio, location;
                """
                cursor.execute(update_query, (
                    psycopg2.Binary(decoded_image),
                    content_type,
                    user_id
                ))
                updated_profile = cursor.fetchone()
                conn.commit()

                if not updated_profile:
                    return cors_response(404, {'error': 'Profile not found'})

                # Then fetch the full profile including the new image
                get_profile_query = """
                SELECT id, userId, bio, location, 
                    encode(profilePicture, 'base64') as profilepicture_base64,
                    content_type
                FROM userProfile
                WHERE userId = %s
                """
                cursor.execute(get_profile_query, (user_id,))
                full_profile = cursor.fetchone()

                # Format the response
                response_profile = {
                    'id': full_profile['id'],
                    'userId': full_profile['userid'],
                    'bio': full_profile['bio'],
                    'location': full_profile['location']
                }

                if full_profile['profilepicture_base64'] and full_profile['content_type']:
                    response_profile['profilePicture'] = f"data:{full_profile['content_type']};base64,{full_profile['profilepicture_base64']}"

                return cors_response(200, {
                    'message': 'Profile picture updated successfully',
                    'profile': response_profile
                })

    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return cors_response(500, {'error': f'Server error: {str(e)}'})