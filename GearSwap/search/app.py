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
def postSearch(event, context):
    try:
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = json.loads(event.get('body', '{}'))

        userId = event['pathParameters']['userId']
        searchQuery = (body.get('searchQuery')) 
        
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

                insert_query = """
                INSERT INTO search (userId, searchQuery) 
                VALUES (%s, %s)
                RETURNING id, userId, searchQuery, timeStamp;
                """
                
                cursor.execute(insert_query, (userId, searchQuery))
                new_search = cursor.fetchone()

                conn.commit()

        return {
            "statusCode": 201,
            "body": json.dumps({
                "message": "Search posted successfully",
                "search": new_search
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