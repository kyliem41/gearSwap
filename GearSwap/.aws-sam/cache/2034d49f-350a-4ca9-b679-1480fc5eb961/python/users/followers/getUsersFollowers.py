import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor

def lambda_handler(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    
    user_id = event['pathParameters']['Id']

    get_followers_query = """
    SELECT u.id, u.username, u.email, u.profileInfo, u.joinDate, u.likeCount, u.saveCount
    FROM users u
    INNER JOIN follows f ON u.id = f.follower_id
    WHERE f.followed_id = %s;
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
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Followers retrieved successfully",
                "followers": followers
            }, default=str)  # Use str as a fallback serializer
        }
        
    except Exception as e:
        print(f"Failed to get followers. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error getting followers: {str(e)}")
        }
    finally:
        if conn:
            conn.close()