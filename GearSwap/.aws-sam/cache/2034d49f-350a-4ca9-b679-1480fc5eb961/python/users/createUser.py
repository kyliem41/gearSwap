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
    
    # Parse the event body (handles if the body is a string)
    try:
        if isinstance(event, str):
            event = json.loads(event)
        elif "body" in event:
            event = json.loads(event["body"])
    except json.JSONDecodeError as e:
        return {
            "statusCode": 400,
            "body": json.dumps(f"Invalid JSON format: {str(e)}")
        }
    
    # Extract fields from the event object
    try:
        username = event['username']
        email = event['email']
        password = event['password']
        profile_info = event.get('profileInfo')  # Optional
    except KeyError as e:
        return {
            "statusCode": 400,
            "body": json.dumps(f"Missing required field: {str(e)}")
        }

    insert_query = """
    INSERT INTO users (username, email, password, profileInfo, joinDate, likeCount, saveCount) 
    VALUES (%s, %s, %s, %s, CURRENT_TIMESTAMP, 0, 0)
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
            cursor.execute(insert_query, (username, email, password, profile_info))
            
            new_user = cursor.fetchone()
            
            conn.commit()
        
        return {
            "statusCode": 201,
            "body": json.dumps({
                "message": "User created successfully",
                "user": new_user
            }, default=json_serial)
        }
        
    except psycopg2.IntegrityError as e:
        return {
            "statusCode": 400,
            "body": json.dumps("Username or email already exists")
        }
    except Exception as e:
        print(f"Failed to create user. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error creating user: {str(e)}")
        }
    finally:
        if conn:
            conn.close()
