import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime
from decimal import Decimal
import jwt
import requests
from jwt.algorithms import RSAAlgorithm

def lambda_handler(event, context):
    http_method = event['httpMethod']
    resource_path = event['resource']

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