import base64
import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime
import boto3
from botocore.exceptions import ClientError
import jwt
import requests
from jwt.algorithms import RSAAlgorithm

def cors_response(status_code, body, content_type='application/json'):
    headers = {
        'Content-Type': content_type,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE'
    }
    
    if content_type == 'application/json':
        body = json.dumps(body, default=str)
        is_base64 = False
    else:
        is_base64 = True
    
    return {
        'statusCode': status_code,
        'headers': headers,
        'body': body,
        'isBase64Encoded': is_base64
    }
    
def parse_body(event):
    """Helper function to parse request body handling both base64 and regular JSON"""
    try:
        if event.get('isBase64Encoded', False):
            decoded_body = base64.b64decode(event['body']).decode('utf-8')
            try:
                return json.loads(decoded_body)
            except json.JSONDecodeError:
                return decoded_body
        elif isinstance(event.get('body'), dict):
            return event['body']
        elif isinstance(event.get('body'), str):
            return json.loads(event['body'])
        return {}
    except Exception as e:
        print(f"Error parsing body: {str(e)}")
        raise ValueError(f"Invalid request body: {str(e)}")

def lambda_handler(event, context):
    if event['httpMethod'] == 'OPTIONS':
        return cors_response(200, {'message': 'OK'})
    
    http_method = event['httpMethod']
    resource_path = event['resource']

    # Skip authentication for user creation
    if resource_path == '/users' and http_method == 'POST':
        return createUser(event, context)

    # Verify token for all other endpoints
    try:        
        auth_header = event.get('headers', {}).get('Authorization')
        if not auth_header:
            return cors_response(401, {'error': 'No authorization header'})

        # Extract token from Bearer authentication
        token = auth_header.split(' ')[-1]        
        verify_token(token)
    except Exception as e:
        return cors_response(401, {'error': f'Authentication failed: {str(e)}'})

    try:
        if resource_path == '/users':
            if http_method == 'GET':
                return getUsers(event, context)
        elif resource_path == '/users/{Id}':
            if http_method == 'GET':
                return getUserById(event, context)
            elif http_method == 'PUT':
                return putUser(event, context)
            elif http_method == 'DELETE':
                return deleteUser(event, context)
        elif resource_path == '/users/password/{Id}':
            return updatePassword(event, context)
        elif resource_path == '/users/follow/{Id}':
                return followUser(event, context)
        elif resource_path == '/users/following/{Id}':
            return getUsersFollowing(event, context)
        elif resource_path == '/users/followers/{Id}':
            return getUsersFollowers(event, context)

        return cors_response(404, {'error': 'Route not found'})
        
    except Exception as e:
        return cors_response(500, {'error': str(e)})

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
    
#########################
def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} not serializable")

###############
def getUsers(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']

    try:
    
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
        )
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            get_query = "SELECT * FROM users ORDER BY id"
            cursor.execute(get_query)
            users = cursor.fetchall()
            
        return cors_response(200, {
            "message": "All users retrieved",
            "users": users,
            "total_count": len(users)
        })
        
    except Exception as e:
        print(f"Failed to get users. Error: {str(e)}")
        return cors_response(500, {
            "error": f"Error getting users: {str(e)}"
        })
        
    finally:
        if conn:
            conn.close()
            
##################
#profile-pic
def get_default_profile_picture():
    """Read the default profile picture from the package resources"""
    try:
        file_path = os.path.join(os.path.dirname(__file__), 'default_profile.png')
        with open(file_path, 'rb') as f:
            return f.read()
    except Exception as e:
        print(f"Error reading default profile picture: {str(e)}")
        return None

################
def createUser(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    user_pool_id = os.environ['COGNITO_USER_POOL_ID']
    
    conn = None
    cognito_client = boto3.client('cognito-idp')

    try:
        try:
            body = parse_body(event)
        except ValueError as e:
            return cors_response(400, {'error': str(e)})

        firstName = body.get('firstName')
        lastName = body.get('lastName')
        username = body.get('username')
        email = body.get('email')
        password = body.get('password')

        if not firstName or not lastName or not username or not email or not password:
            return cors_response(400, "Missing required fields: firstname, lastname, username, email, or password")

        profile_info = body.get('profileInfo')

        try:
            cognito_response = cognito_client.admin_create_user(
                UserPoolId=user_pool_id,
                Username=email,
                UserAttributes=[
                    {'Name': 'email', 'Value': email},
                    {'Name': 'preferred_username', 'Value': username},
                    {'Name': 'given_name', 'Value': firstName},
                    {'Name': 'family_name', 'Value': lastName},
                    {'Name': 'email_verified', 'Value': 'true'}
                ],
                TemporaryPassword=password,
                MessageAction='SUPPRESS',
                ForceAliasCreation=True
            )

            cognito_client.admin_set_user_password(
                UserPoolId=user_pool_id,
                Username=email,
                Password=password,
                Permanent=True
            )
            
            default_profile_picture = get_default_profile_picture()

            conn = psycopg2.connect(
                host=db_host,
                user=db_user,
                password=db_password,
                port=db_port,
            )

            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # First, insert the user
                insert_user_query = """
                INSERT INTO users (firstName, lastName, username, email, password, profileInfo, joinDate, likeCount) 
                VALUES (%s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP, 0)
                RETURNING id, firstName, lastName, username, email, profileInfo, joinDate, likeCount;
                """
                cursor.execute(insert_user_query, (firstName, lastName, username, email, password, profile_info))
                new_user = cursor.fetchone()
                
                # Default values for user profile
                default_bio = f"Hi, I'm {username}"
                default_location = "I'm here"
                
                # Then, create the user profile with the returned user ID
                insert_profile_query = """
                INSERT INTO userProfile (userId, username, bio, location, profilePicture, content_type) 
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id, userId, username, bio, location;
                """
                cursor.execute(insert_profile_query, (
                    new_user['id'], 
                    username, 
                    default_bio,
                    default_location,
                    psycopg2.Binary(default_profile_picture) if default_profile_picture else None,
                    'image/png'
                ))
                new_profile = cursor.fetchone()
                
                # Update the user's profileInfo with the new profile ID
                update_user_query = """
                UPDATE users 
                SET profileInfo = %s 
                WHERE id = %s
                RETURNING id, firstName, lastName, username, email, profileInfo, joinDate, likeCount;
                """
                cursor.execute(update_user_query, (new_profile['id'], new_user['id']))
                updated_user = cursor.fetchone()
                
                conn.commit()

            return cors_response(201, {
            "message": "User and profile created successfully",
            "user": updated_user,
            "profile": new_profile,
            "cognitoUser": cognito_response['User']
        })

        except ClientError as e:
            print(f"Cognito error: {str(e)}")
            return cors_response(400, f"Error creating Cognito user: {str(e)}")

    except Exception as e:
        print(f"Error: {str(e)}")
        return cors_response(500, f"Error creating user: {str(e)}")

    finally:
        if conn:
            conn.close()
            
################            
def getUserById(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    
    user_id = event['pathParameters']['Id']

    try:
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
        )
        
        if not conn:
            return cors_response(500, "Failed to connect to database")
            
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            get_query = "SELECT * FROM users WHERE id = %s"
            cursor.execute(get_query, (user_id))
            user = cursor.fetchone()

        if user:
            return cors_response(200, {
            "message": "User retrieved successfully",
            "user": user
            })
        else:
            return cors_response(404, "User not found")
            
    except Exception as e:
        print(f"Failed to get user. Error: {str(e)}")
        print(f"Connection details: host={db_host}, user={db_user}, port={db_port}")
        return cors_response(500, f"Error getting user: {str(e)}")

    finally:
        if conn:
            conn.close()

#########
def putUser(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    
    try:
        body = parse_body(event)
    except ValueError as e:
        return cors_response(400, {'error': str(e)})
    
    user_id = event['pathParameters']['Id']
    new_username = body['username']
    
    update_query = """
    UPDATE users 
    SET username = %s 
    WHERE id = %s 
    RETURNING id, firstName, lastName, username, email, profileInfo, joinDate, likeCount;
    """
    
    try:
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
        )
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(update_query, (new_username, user_id))
            updated_user = cursor.fetchone()
            
            conn.commit()
        
        if updated_user:
            return cors_response(200, {
                "message": "Username updated successfully",
                "user": updated_user
            })

        else:
            return cors_response(404, "User not found")
        
    except psycopg2.IntegrityError as e:
        return cors_response(400, "Username already exists")
    except Exception as e:
        print(f"Failed to update username. Error: {str(e)}")
        return cors_response(500, f"Error updating username: {str(e)}")

    finally:
        if conn:
            conn.close()
            
###############
def updatePassword(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    user_pool_id = os.environ['COGNITO_USER_POOL_ID']
    
    conn = None
    cognito_client = boto3.client('cognito-idp')

    try:
        try:
            body = parse_body(event)
        except ValueError as e:
            return cors_response(400, {'error': str(e)})
        
        user_id = event['pathParameters']['Id']
        new_password = body.get('password')

        if not new_password:
            return cors_response(400, "Missing required field: password")

        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
        )

        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            # Get user email
            get_email_query = "SELECT email FROM users WHERE id = %s"
            cursor.execute(get_email_query, (user_id,))
            user = cursor.fetchone()
            
            if not user:
                return cors_response(404, "User not found")

            user_email = user['email']

            # Update password in database
            update_query = """
            UPDATE users 
            SET password = %s 
            WHERE id = %s 
            RETURNING id, email;
            """
            cursor.execute(update_query, (new_password, user_id))
            updated_user = cursor.fetchone()
            conn.commit()

        # Update password in Cognito
        try:
            cognito_client.admin_set_user_password(
                UserPoolId=user_pool_id,
                Username=user_email,
                Password=new_password,
                Permanent=True
            )

            return cors_response(200, {
                "message": "Password updated successfully",
                "userId": updated_user['id']
            })

        except Exception as e:
            print(f"Cognito error: {str(e)}")
            return cors_response(500, f"Error updating Cognito password: {str(e)}")

    except Exception as e:
        print(f"Error: {str(e)}")
        return cors_response(500, f"Error updating password: {str(e)}")

    finally:
        if conn:
            conn.close()

#############
def deleteUser(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    user_pool_id = os.environ['COGNITO_USER_POOL_ID']    
    cognito_client = boto3.client('cognito-idp')
    
    user_id = event['pathParameters']['Id']

    delete_query = "DELETE FROM users WHERE id = %s RETURNING id;"
    
    try:
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
        )
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            get_email_query = "SELECT email FROM users WHERE id = %s"
            cursor.execute(get_email_query, (user_id,))
            user_record = cursor.fetchone()
            
            if not user_record:
                return cors_response(404, "User not found")
            
            user_email = user_record['email']
            
            delete_query = "DELETE FROM users WHERE id = %s RETURNING id;"
            cursor.execute(delete_query, (user_id,))
            deleted_user = cursor.fetchone()
            
            conn.commit()

        try:
            cognito_client.admin_delete_user(
                UserPoolId=user_pool_id,
                Username=user_email
            )
        except cognito_client.exceptions.UserNotFoundException:
            print(f"User {user_email} not found in Cognito")
        except Exception as cognito_error:
            print(f"Error deleting user from Cognito: {str(cognito_error)}")
            return cors_response(207, {
                "message": "User deleted from database but failed to delete from Cognito",
                "deletedUserId": deleted_user['id'],
                "cognitoError": str(cognito_error)
            })
        
        return cors_response(200, {
            "message": "User deleted successfully from both database and Cognito",
            "deletedUserId": deleted_user['id']
        })
        
    except Exception as e:
        print(f"Failed to delete user. Error: {str(e)}")
        return cors_response(500, f"Error deleting user: {str(e)}")

    finally:
        if conn:
            conn.close()

####################
def followUser(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    
    try:
        body = parse_body(event)
    except ValueError as e:
        return cors_response(400, {'error': str(e)})
    
    followed_id = event['pathParameters']['Id']
    follower_id = body['followerId']
    
    try:
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
        )

        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            # Check if already following
            check_query = """
            SELECT * FROM follows 
            WHERE followerId = %s AND followedId = %s
            """
            cursor.execute(check_query, (follower_id, followed_id))
            existing = cursor.fetchone()

            if not existing:
                # If not following, create follow relationship
                follow_query = """
                INSERT INTO follows (followerId, followedId)
                VALUES (%s, %s)
                RETURNING followerId, followedId;
                """
                cursor.execute(follow_query, (follower_id, followed_id))
                follow_record = cursor.fetchone()
                
                conn.commit()
                
                return cors_response(201, {
                    "message": "User followed successfully",
                    "followRecord": follow_record
                })

            else:
                # If already following, delete the relationship
                unfollow_query = """
                DELETE FROM follows 
                WHERE followerId = %s AND followedId = %s
                RETURNING followerId, followedId;
                """
                cursor.execute(unfollow_query, (follower_id, followed_id))
                unfollow_record = cursor.fetchone()
                
                conn.commit()
                
                return cors_response(200, {
                    "message": "User unfollowed successfully",
                    "unfollowRecord": unfollow_record
                })
    
    except Exception as e:
        print(f"Failed to follow/unfollow user. Error: {str(e)}")
        return cors_response(500, f"Error following/unfollowing user: {str(e)}")

    finally:
        if conn:
            conn.close()

##########
def getUsersFollowing(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    
    user_id = event['pathParameters']['Id']

    get_following_query = """
    SELECT u.id, u.firstName, u.lastName, u.username, u.email, u.profileInfo, u.joinDate, u.likeCount
    FROM users u
    INNER JOIN follows f ON u.id = f.followedId
    WHERE f.followerId = %s;
    """
    
    try:
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
        )
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(get_following_query, (user_id,))
            following = cursor.fetchall()
        
        return cors_response(200, {
            "message": "Following users retrieved successfully",
            "following": following
        })
        
    except Exception as e:
        print(f"Failed to get following users. Error: {str(e)}")
        return cors_response(500, f"Error getting following users: {str(e)}")
        
    finally:
        if conn:
            conn.close()

##########
def getUsersFollowers(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    
    user_id = event['pathParameters']['Id']

    get_followers_query = """
    SELECT u.id, u.firstName, u.lastName, u.username, u.email, u.profileInfo, u.joinDate, u.likeCount
    FROM users u
    INNER JOIN follows f ON u.id = f.followerId
    WHERE f.followedId = %s;
    """
    
    try:
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
        )
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(get_followers_query, (user_id,))
            followers = cursor.fetchall()
        
        return cors_response(200, {
            "message": "Followers retrieved successfully",
            "followers": followers
        })
        
    except Exception as e:
        print(f"Failed to get followers. Error: {str(e)}")
        return cors_response(500, f"Error getting followers: {str(e)}")

    finally:
        if conn:
            conn.close()