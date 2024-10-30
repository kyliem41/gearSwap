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

def lambda_handler(event, context):
    http_method = event['httpMethod']
    resource_path = event['resource']
    
    try:
        auth_header = event.get('headers', {}).get('Authorization')
        if not auth_header:
            return {
                'statusCode': 401,
                'body': json.dumps({'error': 'No authorization header'})
            }

        # Extract token from Bearer authentication
        token = auth_header.split(' ')[-1]
        verify_token(token)
    except Exception as e:
        return {
            'statusCode': 401,
            'body': json.dumps({'error': f'Authentication failed: {str(e)}'})
        }

    if resource_path == '/search/{userId}':
        if http_method == 'POST':
            return postSearch(event, context)
        elif http_method == 'GET':
            return getSearchHistory(event, context)
    elif resource_path == '/search/{userId}/{searchId}':
        if http_method == 'DELETE':
            return deleteSearch(event, context)

    return {
        'statusCode': 400,
        'body': json.dumps('Unsupported route')
    }
    
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
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = json.loads(event.get('body', '{}'))

        userId = event['pathParameters']['userId']
        searchQuery = (body.get('searchQuery', '')).lower()
        
        required_fields = ['searchQuery']
        for field in required_fields:
            if field not in body:
                return {
                    "statusCode": 400,
                    "body": json.dumps(f"Missing required field: {field}")
                }

    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "body": json.dumps("Invalid JSON format in request body")
        }

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Check if the user exists and get their username
                cursor.execute("SELECT username FROM users WHERE id = %s", (userId,))
                user = cursor.fetchone()
                if not user:
                    return {
                        "statusCode": 404,
                        "body": json.dumps("User not found")
                    }

                # Save the search query
                insert_query = """
                INSERT INTO search (userId, searchQuery) 
                VALUES (%s, %s)
                RETURNING id, userId, searchQuery, timeStamp;
                """
                
                cursor.execute(insert_query, (userId, searchQuery))
                new_search = cursor.fetchone()
                
                # Get filtered posts
                search_pattern = f'%{searchQuery}%'
                get_posts_query = """
                    SELECT 
                        id,
                        userid,
                        CAST(price AS float) as price,
                        description,
                        size,
                        category,
                        clothingtype,
                        tags,
                        photos,
                        dateposted,
                        likecount
                    FROM posts 
                    WHERE 
                        LOWER(description) LIKE %s 
                        OR LOWER(category) LIKE %s
                        OR LOWER(clothingtype) LIKE %s
                        OR EXISTS (
                            SELECT 1 FROM jsonb_array_elements_text(tags) tag 
                            WHERE LOWER(tag) LIKE %s
                        )
                    ORDER BY dateposted DESC;
                """
                
                cursor.execute(get_posts_query, (search_pattern, search_pattern, search_pattern, search_pattern))
                filtered_posts = cursor.fetchall()

                conn.commit()

        return {
            "statusCode": 201,
            "body": json.dumps({
                "message": "Search posted successfully",
                "search": new_search,
                "posts": filtered_posts,
                "total_count": len(filtered_posts)
            }, default=json_serial)
        }

    except Exception as e:
        print(f"Failed to post search. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error posting search: {str(e)}")
        }

################
def getSearchHistory(event, context):
    try:
        userId = event['pathParameters']['userId']
        
        if not userId:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "User ID is required"})
            }

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

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Recent searches retrieved",
                "searches": searches,
                "total_count": len(searches)
            }, default=json_serial)
        }
            
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Error getting searches: {str(e)}"})
        }
    finally:
        if conn:
            conn.close()
            
###########
def deleteSearch(event, context):
    try:
        userId = event['pathParameters']['userId']
        searchId = event['pathParameters']['searchId']
        
        if not searchId:
            return {
                "statusCode": 400,
                "body": json.dumps("Missing searchId in path parameters")
            }
        
    except KeyError as e:
        return {
            "statusCode": 400,
            "body": json.dumps(f"Missing required parameter: {str(e)}")
        }
        
    delete_query = "DELETE FROM search WHERE id = %s AND userId = %s RETURNING id;"

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(delete_query, (searchId, userId))
                deleted_search = cursor.fetchone()
                conn.commit()
        
        if deleted_search:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Post deleted successfully",
                    "deletedSearchId": deleted_search['id']
                })
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("Search not found or does not belong to the user")
            }
        
    except Exception as e:
        print(f"Failed to delete search. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error deleting search: {str(e)}")
        }
        
    finally:
        if conn:
            conn.close()