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

    delete_query = "DELETE FROM users WHERE id = %s RETURNING id;"
    
    try:
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
        )
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(delete_query, (user_id,))
            deleted_user = cursor.fetchone()
            
            conn.commit()
        
        if deleted_user:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "User deleted successfully",
                    "deletedUserId": deleted_user['id']
                })
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("User not found")
            }
        
    except Exception as e:
        print(f"Failed to delete user. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error deleting user: {str(e)}")
        }
    finally:
        if conn:
            conn.close()