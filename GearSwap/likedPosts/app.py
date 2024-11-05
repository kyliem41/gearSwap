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

    if resource_path == '/likedPosts/{userId}':
        if http_method == 'POST':
            return addLikedPost(event, context)
        elif http_method == 'GET':
            return getLikedPosts(event, context)
    elif resource_path == '/likedPosts/{userId}/{postId}':
        if http_method == 'DELETE':
            return removeLikedPost(event, context)
        elif http_method == 'GET':
            return getLikedPostById(event, context)

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
def addLikedPost(event, context):
    try:
        body = json.loads(event['body']) if isinstance(event.get('body'), str) else event.get('body', {})
        
        userId = event['pathParameters']['userId']
        postId = body.get('postId')
        
        if not postId:
            return cors_response(400, {"error": "Missing required field: postId"})

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                insert_query = """
                INSERT INTO likedPost (userId, postId) 
                VALUES (%s, %s)
                RETURNING id, userId, postId, dateLiked;
                """
                
                cursor.execute(insert_query, (userId, postId))
                new_liked_post = cursor.fetchone()
                conn.commit()

        return cors_response(201, {
            "message": "Post liked successfully",
            "likedPost": new_liked_post
        })

    except Exception as e:
        print(f"Failed to add liked post. Error: {str(e)}")
        return cors_response(500, {"error": f"Error adding liked post: {str(e)}"})

################
def getLikedPosts(event, context):
    try:
        userId = event['pathParameters']['userId']
        
        if not userId:
            return cors_response(400, {"error": "User ID is required"})

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                get_query = """
                    SELECT p.*, lp.dateLiked
                    FROM likedPost lp
                    JOIN posts p ON lp.postId = p.id
                    WHERE lp.userId = %s 
                    ORDER BY lp.dateLiked DESC 
                """
                cursor.execute(get_query, (userId,))
                likedPosts = cursor.fetchall()

                # Convert decimal values to float for JSON serialization
                for post in likedPosts:
                    if 'price' in post and isinstance(post['price'], Decimal):
                        post['price'] = float(post['price'])

        return cors_response(200, {
            "message": "Liked posts retrieved",
            "posts": likedPosts
        })
            
    except Exception as e:
        print(f"Error getting liked posts: {str(e)}")
        return cors_response(500, {"error": f"Error getting liked posts: {str(e)}"})

    finally:
        if conn:
            conn.close()
            
###########
def removeLikedPost(event, context):
    try:
        userId = event['pathParameters']['userId']
        postId = event['pathParameters']['postId']
        
        if not postId:
            return cors_response(400, {"error": "Missing postId in path parameters"})
        
    except KeyError as e:
        return cors_response(400, {"error": f"Missing required parameter: {str(e)}"})
        
    delete_query = "DELETE FROM likedPost WHERE postId = %s AND userId = %s RETURNING id;"

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(delete_query, (postId, userId))
                removed_search = cursor.fetchone()
                conn.commit()
        
        if removed_search:
            return cors_response(200, {
                "message": "Post removed successfully",
                "removedPostId": removed_search['id']
            })
            
        else:
            return cors_response(404, {"error": "Post not found or does not belong to the user"})
        
    except Exception as e:
        print(f"Failed to remove post. Error: {str(e)}")
        return cors_response(500, {"error": f"Error removing post: {str(e)}"})
        
    finally:
        if conn:
            conn.close()
            
################
def getLikedPostById(event, context):
    conn = None
    try:
        userId = event['pathParameters']['userId']
        postId = event['pathParameters']['postId']
        
        if not userId or not postId:
            return cors_response(400, {"error": "Both User ID and Post ID are required"})

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                get_query = """
                    SELECT * FROM likedPost 
                    WHERE postId = %s AND userId = %s 
                """
                cursor.execute(get_query, (postId, userId))
                likedPost = cursor.fetchone()

        if likedPost:
            return cors_response(200, {
                "message": "Liked post retrieved successfully",
                "post": likedPost
            })

        else:
            return cors_response(404, {"error": "Liked post not found"})
            
    except Exception as e:
        print(f"Error in getLikedPostById: {str(e)}")
        return cors_response(500, {"error": f"An error occurred while retrieving the liked post: {str(e)}"})

    finally:
        if conn:
            conn.close()