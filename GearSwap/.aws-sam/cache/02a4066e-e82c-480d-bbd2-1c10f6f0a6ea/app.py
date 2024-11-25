import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime
from decimal import Decimal
import jwt
import requests
from jwt.algorithms import RSAAlgorithm
import boto3
import base64

def cors_response(status_code, body):
    """Helper function to create responses with proper CORS headers"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',  # Configure this to match your domain in production
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE'
        },
        'body': json.dumps(body, default=str)
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

    if resource_path == '/search/{userId}':
        if http_method == 'POST':
            return postSearch(event, context)
        elif http_method == 'GET':
            return getSearchHistory(event, context)
    elif resource_path == '/search/{userId}/{searchId}':
        if http_method == 'DELETE':
            return deleteSearch(event, context)

    return cors_response(400, {'error': 'Unsupported route'})
    
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
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Type {type(obj)} not serializable")

#########
def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT'],
        
        connect_timeout=5
    )

###########
def postSearch(event, context):
    try:
        try:
            if isinstance(event.get('body'), str):
                decoded_body = base64.b64decode(event['body']).decode('utf-8')
                body = json.loads(decoded_body)
            else:
                body = event.get('body', {})
        except Exception as e:
            print(f"Error decoding/parsing body: {str(e)}")
            print(f"Raw body: {event.get('body')}")
            return cors_response(400, {'error': f"Invalid request body: {str(e)}"})
        
        userId = event.get('pathParameters', {}).get('userId')
        if not userId:
            return cors_response(400, {"error": "Missing userId in path parameters"})

        searchQuery = body.get('searchQuery', '').strip().lower()
        if not searchQuery:
            return cors_response(400, {"error": "searchQuery is required and cannot be empty"})

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("SELECT username FROM users WHERE id = %s", (userId,))
                user = cursor.fetchone()
                if not user:
                    return cors_response(404, {"error": "User not found"})

                # Save the search query
                insert_query = """
                INSERT INTO search (userId, searchQuery) 
                VALUES (%s, %s)
                RETURNING id, userId, searchQuery, timeStamp;
                """
                cursor.execute(insert_query, (userId, searchQuery))
                new_search = cursor.fetchone()
                
                # Get filtered posts with improved search and image handling
                search_terms = [term.strip() for term in searchQuery.split()]
                search_conditions = []
                search_params = []
                
                for term in search_terms:
                    pattern = f'%{term}%'
                    search_conditions.extend([
                        "LOWER(description) LIKE %s",
                        "LOWER(category) LIKE %s",
                        "LOWER(clothingtype) LIKE %s",
                        "EXISTS (SELECT 1 FROM jsonb_array_elements_text(tags) tag WHERE LOWER(tag) LIKE %s)"
                    ])
                    search_params.extend([pattern] * 4)

                search_query = f"""
                    SELECT 
                        p.*,
                        u.username,
                        COALESCE(
                            (
                                SELECT json_agg(
                                    json_build_object(
                                        'id', pi.id,
                                        'content_type', pi.content_type,
                                        'data', encode(pi.image_data, 'base64')
                                    )
                                )
                                FROM (
                                    SELECT id, content_type, image_data
                                    FROM post_images
                                    WHERE post_id = p.id
                                    ORDER BY id
                                    LIMIT 1
                                ) pi
                            ),
                            '[]'::json
                        ) as images
                    FROM posts p
                    JOIN users u ON p.userId = u.id
                    WHERE {' OR '.join(search_conditions)}
                    ORDER BY p.dateposted DESC
                """
                
                cursor.execute(search_query, search_params)
                filtered_posts = cursor.fetchall()

                conn.commit()

                return cors_response(201, {
                    "message": "Search successful",
                    "search": new_search,
                    "posts": filtered_posts,
                    "total_count": len(filtered_posts)
                })

    except psycopg2.Error as e:
        print(f"Database error: {str(e)}")
        return cors_response(500, {"error": "Database operation failed"})
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return cors_response(500, {"error": f"An unexpected error occurred"})
    
################
def getSearchHistory(event, context):
    try:
        userId = event['pathParameters']['userId']
        
        if not userId:
            return cors_response(400, "User ID is required")

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                get_query = """
                    SELECT * FROM search 
                    WHERE userId = %s 
                    ORDER BY timestamp DESC 
                    LIMIT 5
                """
                cursor.execute(get_query, (userId,))
                searches = cursor.fetchall()

        return cors_response(200, {
            "message": "Recent searches retrieved",
            "searches": searches,
            "total_count": len(searches)
        })
            
    except Exception as e:
        return cors_response(500, f"Error getting searches: {str(e)}")

    finally:
        if conn:
            conn.close()
            
###########
def deleteSearch(event, context):
    try:
        userId = event['pathParameters']['userId']
        searchId = event['pathParameters']['searchId']
        
        if not searchId:
            return cors_response(400, "Missing searchId in path parameters")
        
    except KeyError as e:
        return cors_response(400, f"Missing required parameter: {str(e)}")
        
    delete_query = "DELETE FROM search WHERE id = %s AND userId = %s RETURNING id;"

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(delete_query, (searchId, userId))
                deleted_search = cursor.fetchone()
                conn.commit()
        
        if deleted_search:
            return cors_response(200, {
                "message": "Post deleted successfully",
                "deletedSearchId": deleted_search['id']
            })

        else:
            return cors_response(404, "Search not found or does not belong to the user")
        
    except Exception as e:
        print(f"Failed to delete search. Error: {str(e)}")
        return cors_response(500, f"Error deleting search: {str(e)}")
        
    finally:
        if conn:
            conn.close()