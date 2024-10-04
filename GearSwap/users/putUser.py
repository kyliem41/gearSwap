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
    new_username = json.loads(event['body'])['username']

    update_query = """
    UPDATE users 
    SET username = %s 
    WHERE id = %s 
    RETURNING id, username, email, profileInfo, joinDate, likeCount, saveCount;
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
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Username updated successfully",
                    "user": updated_user
                }, default=str)  # Use str as a fallback serializer
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("User not found")
            }
        
    except psycopg2.IntegrityError as e:
        return {
            "statusCode": 400,
            "body": json.dumps("Username already exists")
        }
    except Exception as e:
        print(f"Failed to update username. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error updating username: {str(e)}")
        }
    finally:
        if conn:
            conn.close()