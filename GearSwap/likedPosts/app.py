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
    raise TypeError(f"Type {type(obj)} not serializable")

#########
def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT'],
    )

###########
def addLikedPost(event, context):
    try:
        body = json.loads(event['body']) if isinstance(event.get('body'), str) else event.get('body', {})
        
        userId = event['pathParameters']['userId']
        postId = body.get('postId')
        
        if not postId:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing required field: postId"})
            }

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

        return {
            "statusCode": 201,
            "body": json.dumps({
                "message": "Post liked successfully",
                "likedPost": new_liked_post
            }, default=json_serial)
        }

    except Exception as e:
        print(f"Failed to add liked post. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Error adding liked post: {str(e)}"})
        }

################
def getLikedPosts(event, context):
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
                    SELECT * FROM likedPost 
                    WHERE userId = %s 
                    ORDER BY dateLiked DESC 
                """
                cursor.execute(get_query, (userId,))
                likedPosts = cursor.fetchall()

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Recent posts retrieved",
                "posts": likedPosts,
                "total_count": len(likedPosts)
            }, default=json_serial)
        }
            
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Error getting posts: {str(e)}"})
        }
    finally:
        if conn:
            conn.close()
            
###########
def removeLikedPost(event, context):
    try:
        userId = event['pathParameters']['userId']
        postId = event['pathParameters']['postId']
        
        if not postId:
            return {
                "statusCode": 400,
                "body": json.dumps("Missing postId in path parameters")
            }
        
    except KeyError as e:
        return {
            "statusCode": 400,
            "body": json.dumps(f"Missing required parameter: {str(e)}")
        }
        
    delete_query = "DELETE FROM likedPost WHERE postId = %s AND userId = %s RETURNING id;"

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(delete_query, (postId, userId))
                removed_search = cursor.fetchone()
                conn.commit()
        
        if removed_search:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Post removed successfully",
                    "removedPostId": removed_search['id']
                })
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("Post not found or does not belong to the user")
            }
        
    except Exception as e:
        print(f"Failed to remove post. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error removing post: {str(e)}")
        }
        
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
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Both User ID and Post ID are required"})
            }

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                get_query = """
                    SELECT * FROM likedPost 
                    WHERE postId = %s AND userId = %s 
                """
                cursor.execute(get_query, (postId, userId))
                likedPost = cursor.fetchone()

        if likedPost:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Liked post retrieved successfully",
                    "post": likedPost
                }, default=json_serial)
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps({"message": "Liked post not found"})
            }
            
    except Exception as e:
        print(f"Error in getLikedPostById: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "An error occurred while retrieving the liked post"})
        }
    finally:
        if conn:
            conn.close()