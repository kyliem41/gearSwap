import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime
import boto3
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    http_method = event['httpMethod']
    resource_path = event['resource']

    if resource_path == '/users':
        if http_method == 'GET':
            return getUsers(event, context)
        elif http_method == 'POST':
            return createUser(event, context)
    elif resource_path == '/users/{Id}':
        if http_method == 'GET':
            return getUserById(event, context)
        elif http_method == 'PUT':
            return putUser(event, context)
        elif http_method == 'DELETE':
            return deleteUser(event, context)
    elif resource_path == '/users/following/{Id}':
        return getUsersFollowing(event, context)
    elif resource_path == '/users/followers/{Id}':
        return getUsersFollowers(event, context)

    return {
        'statusCode': 400,
        'body': json.dumps('Unsupported route')
    }

#########################
def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} not serializable")

###############
def getUsers(event, context):
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
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            get_query = "SELECT * FROM users ORDER BY id"
            cursor.execute(get_query)
            users = cursor.fetchall()

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "All users retrieved",
                "users": users,
                "total_count": len(users)
            }, default=json_serial)
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

################
def createUser(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    user_pool_id = os.environ['COGNITO_USER_POOL_ID']

    conn = None
    cognito_client = boto3.client('cognito-idp')
    
    print(cognito_client)
    print(user_pool_id)

    try:
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})

        firstName = body.get('firstName')
        lastName = body.get('lastName')
        username = body.get('username')
        email = body.get('email')
        password = body.get('password')

        if not firstName or not lastName or not username or not email or not password:
            return {
                "statusCode": 400,
                "body": json.dumps("Missing required fields: firstname, lastname, username, email, or password")
            }

        profile_info = body.get('profileInfo')  # Optional field
        
        print("test 1")

        # Create user in Cognito
        try:
            cognito_response = cognito_client.admin_create_user(
                UserPoolId=user_pool_id,
                Username=username,
                UserAttributes=[
                    {'Name': 'email', 'Value': email},
                    {'Name': 'given_name', 'Value': firstName},
                    {'Name': 'family_name', 'Value': lastName},
                    {'Name': 'email_verified', 'Value': 'true'}
                ],
                TemporaryPassword=password,
                MessageAction='SUPPRESS'
            )
            
            print("test 2")

            # Set the user's password permanently
            cognito_client.admin_set_user_password(
                UserPoolId=user_pool_id,
                Username=username,
                Password=password,
                Permanent=True
            )
        except ClientError as e:
            return {
                "statusCode": 400,
                "body": json.dumps(f"Error creating Cognito user: {str(e)}")
            }

        # If Cognito user creation is successful, proceed with database insertion
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
        )
        
        print("test 3")

        insert_query = """
        INSERT INTO users (firstName, lastName, username, email, password, profileInfo, joinDate, likeCount) 
        VALUES (%s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP, 0)
        RETURNING id, firstName, lastName, username, email, profileInfo, joinDate, likeCount;
        """

        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(insert_query, (firstName, lastName, username, email, password, profile_info))
            new_user = cursor.fetchone()
            conn.commit()
            
        print("test 4")

        return {
            "statusCode": 201,
            "body": json.dumps({
                "message": "User created successfully in both Cognito and database",
                "user": new_user,
                "cognitoUser": cognito_response['User']
            }, default=str)
        }

    except psycopg2.IntegrityError as e:
        # If database insertion fails, we should delete the Cognito user
        cognito_client.admin_delete_user(
            UserPoolId=user_pool_id,
            Username=username
        )
        return {
            "statusCode": 409,
            "body": json.dumps(f"Username or email already exists: {str(e)}")
        }

    except Exception as e:
        print(f"Failed to create user. Error: {str(e)}")
        # If an exception occurs after Cognito user creation, we should delete the Cognito user
        try:
            cognito_client.admin_delete_user(
                UserPoolId=user_pool_id,
                Username=username
            )
        except:
            pass
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error creating user: {str(e)}")
        }

    finally:
        if conn:
            conn.close()
            
################            
def getUserById(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    
    user_id = event['pathParameters']['Id']

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
            get_query = "SELECT * FROM users WHERE id = %s"
            cursor.execute(get_query, (user_id))
            user = cursor.fetchone()

        if user:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "User retrieved successfully",
                    "user": user
                }, default=json_serial)
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("User not found")
            }
            
    except Exception as e:
        print(f"Failed to get user. Error: {str(e)}")
        print(f"Connection details: host={db_host}, user={db_user}, port={db_port}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error getting user: {str(e)}"),
        }
    finally:
        if conn:
            conn.close()

#########
def putUser(event, context):
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
    RETURNING id, firstName, lastName, username, email, profileInfo, joinDate, likeCount;
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

#############
def deleteUser(event, context):
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

##########
def getUsersFollowing(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    
    user_id = event['pathParameters']['Id']

    get_following_query = """
    SELECT u.id, u.firstName, u.lastName, u.username, u.email, u.profileInfo, u.joinDate, u.likeCount
    FROM users u
    INNER JOIN follows f ON u.id = f.followed_id
    WHERE f.follower_id = %s;
    """
    
    try:
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
        )
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(get_following_query, (user_id,))
            following = cursor.fetchall()
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Following users retrieved successfully",
                "following": following
            }, default=str)  # Use str as a fallback serializer
        }
        
    except Exception as e:
        print(f"Failed to get following users. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error getting following users: {str(e)}")
        }
        
    finally:
        if conn:
            conn.close()

##########
def getUsersFollowers(event, context):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = os.environ['DB_PORT']
    
    user_id = event['pathParameters']['Id']

    get_followers_query = """
    SELECT u.id, u.firstName, u.lastName, u.username, u.email, u.profileInfo, u.joinDate, u.likeCount
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