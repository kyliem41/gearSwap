import json
import os
import boto3
import psycopg2
from psycopg2.extras import RealDictCursor
from botocore.exceptions import ClientError
from datetime import datetime

class DateTimeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super(DateTimeEncoder, self).default(obj)

def lambda_handler(event, context):
    print("Starting lambda_handler with event:", json.dumps(event))
    
    try:
        # Parse request body
        print("Attempting to parse request body")
        body = json.loads(event['body'])
        email = body['email']
        password = body['password']
        print(f"Parsed email: {email}")
        print("Password length:", len(password))  # Don't log actual password
    except (KeyError, json.JSONDecodeError) as e:
        print(f"Error parsing request body: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid request body')
        }

    # Initialize Cognito client
    print("Initializing Cognito client")
    cognito_client = boto3.client('cognito-idp')
    user_pool_id = os.environ['COGNITO_USER_POOL_ID']
    client_id = os.environ['COGNITO_CLIENT_ID']
    print(f"Using User Pool ID: {user_pool_id}")
    print(f"Using Client ID: {client_id}")

    try:
        # Verify user exists
        print(f"Verifying user existence for email: {email}")
        try:
            user = cognito_client.admin_get_user(
                UserPoolId=user_pool_id,
                Username=email
            )
            print("User found in Cognito:", json.dumps(user, default=str))
        except cognito_client.exceptions.UserNotFoundException:
            print(f"User not found in Cognito for email: {email}")
            return {
                'statusCode': 404,
                'body': json.dumps('User not found')
            }
        except Exception as e:
            print(f"Unexpected error during user verification: {str(e)}")
            raise

        # Attempt authentication
        print("Attempting authentication")
        try:
            auth_response = cognito_client.admin_initiate_auth(
                UserPoolId=user_pool_id,
                ClientId=client_id,
                AuthFlow='ADMIN_USER_PASSWORD_AUTH',
                AuthParameters={
                    'USERNAME': email,
                    'PASSWORD': password
                }
            )
            print("Authentication successful")
            print("Auth response keys:", auth_response.keys())
        except ClientError as e:
            if e.response['Error']['Code'] == 'NotAuthorizedException':
                print(f"Authentication failed: {str(e)}")
                return {
                    'statusCode': 401,
                    'body': json.dumps({
                        'message': 'Login failed',
                        'body': 'Incorrect username or password'
                    })
                }
            print(f"Unexpected ClientError during authentication: {str(e)}")
            raise e
        except Exception as e:
            print(f"Unexpected error during authentication: {str(e)}")
            raise

        # Get user info from database if authentication successful
        if 'AuthenticationResult' in auth_response:
            print("Getting user info from database")
            user_info = get_user_info_from_db(email)
            print("Retrieved user info:", json.dumps(user_info, cls=DateTimeEncoder))
            
            response_body = {
                'message': 'Login successful',
                'accessToken': auth_response['AuthenticationResult']['AccessToken'],
                'idToken': auth_response['AuthenticationResult']['IdToken'],
                'refreshToken': auth_response['AuthenticationResult']['RefreshToken'],
                'tokenType': auth_response['AuthenticationResult']['TokenType'],
                'expiresIn': auth_response['AuthenticationResult'].get('ExpiresIn', 3600),
                'user': user_info
            }
            print("Preparing successful response")
            
            return {
                'statusCode': 200,
                'body': json.dumps(response_body, cls=DateTimeEncoder)
            }
        
        print("No AuthenticationResult in response")
        return {
            'statusCode': 401,
            'body': json.dumps('Login failed')
        }

    except Exception as e:
        print(f"Error in main try block: {str(e)}")
        print(f"Error type: {type(e)}")
        if hasattr(e, '__traceback__'):
            import traceback
            print("Full traceback:")
            print(traceback.format_exc())
        return {
            'statusCode': 500,
            'body': json.dumps(f'An error occurred during login: {str(e)}')
        }

def get_user_info_from_db(email):
    print(f"Starting database query for email: {email}")
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_port = os.environ['DB_PORT']
    print(f"Database connection details - Host: {db_host}, User: {db_user}, Port: {db_port}")
    
    conn = None
    try:
        print("Attempting database connection")
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=os.environ['DB_PASSWORD'],
            port=db_port,
            
            connect_timeout=5
        )
        print("Database connection successful")
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            query = "SELECT id, firstName, lastName, username, email, profileInfo, joinDate, likeCount FROM users WHERE email = %s"
            print(f"Executing query: {query}")
            cursor.execute(query, (email,))
            user = cursor.fetchone()
            print(f"Query result: {json.dumps(user, cls=DateTimeEncoder) if user else 'No user found'}")

        return user

    except Exception as e:
        print(f"Database error details:")
        print(f"Error type: {type(e)}")
        print(f"Error message: {str(e)}")
        if hasattr(e, '__traceback__'):
            import traceback
            print("Database error traceback:")
            print(traceback.format_exc())
        return None
    finally:
        if conn:
            print("Closing database connection")
            conn.close()
            print("Database connection closed")