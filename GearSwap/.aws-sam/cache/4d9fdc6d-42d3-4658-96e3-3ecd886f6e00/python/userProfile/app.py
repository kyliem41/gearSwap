import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
    http_method = event['httpMethod']
    resource_path = event['resource']

    if resource_path == '/userProfile/{Id}':
        user_id = event['pathParameters']['Id']
        if http_method == 'POST':
            return createProfile(user_id, event)  # Pass user_id here
        elif http_method == 'GET':
            return getUserProfile(user_id)
        elif http_method == 'PUT':
            return putUserProfile(user_id, event)
        elif http_method == 'DELETE':
            return deleteUserProfile(user_id)

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

def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT'],
    )

#############
def createProfile(user_id, event):
    print(f"Creating profile for user_id: {user_id}")
    try:
        body = json.loads(event.get('body', '{}'))
        print(f"Request body: {body}")
    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "body": json.dumps("Invalid JSON format in request body")
        }
    
    bio = body.get('bio')
    location = body.get('location')
    profilePic = body.get('profilePic')

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # First, check if the user exists and get their username
                cursor.execute("SELECT username FROM users WHERE id = %s", (user_id,))
                user = cursor.fetchone()
                if not user:
                    return {
                        "statusCode": 404,
                        "body": json.dumps("User not found")
                    }
                username = user['username']

                insert_query = """
                INSERT INTO userProfile (userId, username, bio, location, profilePic) 
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id, userId, username, bio, location, profilePic;
                """
                cursor.execute(insert_query, (user_id, username, bio, location, profilePic))
                new_profile = cursor.fetchone()
                conn.commit()
        
        return {
            "statusCode": 201,
            "body": json.dumps({
                "message": "UserProfile created successfully",
                "profile": new_profile
            }, default=json_serial)
        }
        
    except psycopg2.IntegrityError as e:
        print(f"IntegrityError: {str(e)}")
        return {
            "statusCode": 400,
            "body": json.dumps("UserProfile for this user already exists")
        }
    except Exception as e:
        print(f"Failed to create profile. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error creating profile: {str(e)}")
        }

################
def getUserProfile(user_id):
    get_query = """
    SELECT up.id, up.userId, u.username, up.bio, up.location, up.profilePic
    FROM userProfile up
    JOIN users u ON up.userId = u.id
    WHERE up.userId = %s
    """
    
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(get_query, (user_id,))
                userProfile = cursor.fetchone()

        if userProfile:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "UserProfile retrieved successfully",
                    "userProfile": userProfile
                }, default=json_serial)
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("UserProfile not found")
            }
            
    except Exception as e:
        print(f"Failed to get profile. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error getting profile: {str(e)}"),
        }

############
def putUserProfile(user_id, event):
    try:
        body = json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "body": json.dumps("Invalid JSON format in request body")
        }

    update_query = """
    UPDATE userProfile    
    SET bio = COALESCE(%s, bio), 
        location = COALESCE(%s, location), 
        profilePic = COALESCE(%s, profilePic)
    WHERE userId = %s 
    RETURNING id, userId, bio, location, profilePic;
    """
    
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(update_query, (body.get('bio'), body.get('location'), body.get('profilePic'), user_id))
                updated_userProfile = cursor.fetchone()
                
                if updated_userProfile:
                    # Fetch the username from the users table
                    cursor.execute("SELECT username FROM users WHERE id = %s", (user_id,))
                    user = cursor.fetchone()
                    if user:
                        updated_userProfile['username'] = user['username']
                
                conn.commit()
        
        if updated_userProfile:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "UserProfile updated successfully",
                    "updated_userProfile": updated_userProfile
                }, default=json_serial)
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("UserProfile not found")
            }
        
    except Exception as e:
        print(f"Failed to update UserProfile. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error updating UserProfile: {str(e)}")
        }

##########
def deleteUserProfile(user_id):
    delete_query = "DELETE FROM userProfile WHERE userId = %s RETURNING id;"
    
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(delete_query, (user_id,))
                deleted_userProfile = cursor.fetchone()
                conn.commit()
        
        if deleted_userProfile:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "UserProfile deleted successfully",
                    "deletedProfileId": deleted_userProfile['id']
                })
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("UserProfile not found")
            }
        
    except Exception as e:
        print(f"Failed to delete UserProfile. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error deleting UserProfile: {str(e)}")
        }