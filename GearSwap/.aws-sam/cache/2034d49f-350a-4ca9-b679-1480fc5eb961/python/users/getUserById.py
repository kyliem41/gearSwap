import psycopg2
import os
import json

def lambda_handler(event, context):
    db_host = os.environ['DB_HOST']
    db_name = os.environ['DB_NAME']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']

    try:
        conn = psycopg2.connect(
            host=db_host,
            dbname=db_name,
            user=db_user,
            password=db_password
        )
        cursor = conn.cursor()

        # user_id = event['pathParameters']['Id']

        # get_query = "SELECT * FROM users WHERE id = %s"
        get_query = "SELECT * FROM users"

        cursor.execute(get_query)#, (user_id,))
        
        user = cursor.fetchone()

        cursor.close()
        conn.close()
        
        if not conn:
            return {
        "statusCode": 500,
        "body": json.dumps("Failed to connect to database")
        }

        if user:
            return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "User retrieved successfully",
            "user": user
        })
    }
        else:
            return {
        "statusCode": 404,
        "body": json.dumps("User not found")
    }
            
    except Exception as e:
        print("failed to get user: ", e)
        return {
            "statusCode": 500,
            "body": f"Error getting user: {str(e)}",
        }
