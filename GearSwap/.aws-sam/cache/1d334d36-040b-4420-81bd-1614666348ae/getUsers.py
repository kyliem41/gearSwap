import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime

def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} not serializable")

def lambda_handler(event, context):
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
        
        if not conn:
            return {
                "statusCode": 500,
                "body": json.dumps("Failed to connect to database")
            }
            
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            get_query = "SELECT * FROM users"
            cursor.execute(get_query)
            users = cursor.fetchall()  # Fetch all users

        if users:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Users retrieved successfully",
                    "users": users  # Return the list of users
                }, default=json_serial)
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("No users found")
            }
            
    except Exception as e:
        print(f"Failed to get users. Error: {str(e)}")
        print(f"Connection details: host={db_host}, user={db_user}, port={db_port}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error getting users: {str(e)}"),
        }
    finally:
        if conn:
            conn.close()
