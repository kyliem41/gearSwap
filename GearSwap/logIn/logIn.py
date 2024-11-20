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
    
def cors_response(status_code, body, content_type='application/json'):
    headers = {
        'Content-Type': content_type,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE'
    }
    
    if content_type == 'application/json':
        body = json.dumps(body, default=str)
        is_base64 = False
    else:
        is_base64 = True
    
    return {
        'statusCode': status_code,
        'headers': headers,
        'body': body,
        'isBase64Encoded': is_base64
    }

def lambda_handler(event, context):
    if event['httpMethod'] == 'OPTIONS':
        return cors_response(200, {'message': 'OK'})
    
    print("Starting lambda_handler with event:", json.dumps(event))
    
    try:
        if event.get('isBase64Encoded', False):
            import base64
            decoded_body = base64.b64decode(event['body']).decode('utf-8')
            body = json.loads(decoded_body)
        else:
            body = json.loads(event['body'])

        email = body['email']
        password = body['password']
    except (KeyError, json.JSONDecodeError) as e:
        print(f"Error parsing request body: {str(e)}")
        return cors_response(400, {'error': 'Invalid request body'})

    cognito_client = boto3.client('cognito-idp')
    user_pool_id = os.environ['COGNITO_USER_POOL_ID']
    client_id = os.environ['COGNITO_CLIENT_ID']
    print(f"Using User Pool ID: {user_pool_id}")
    print(f"Using Client ID: {client_id}")

    try:
        # Verify user exists
        try:
            user = cognito_client.admin_get_user(
                UserPoolId=user_pool_id,
                Username=email
            )
            print("User found in Cognito:", json.dumps(user, default=str))
        except cognito_client.exceptions.UserNotFoundException:
            print(f"User not found in Cognito for email: {email}")
            return cors_response(404, {'error': 'User not found'})
        
        except Exception as e:
            print(f"Unexpected error during user verification: {str(e)}")
            raise

        # Attempt authentication
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
        except ClientError as e:
            if e.response['Error']['Code'] == 'NotAuthorizedException':
                print(f"Authentication failed: {str(e)}")
                return cors_response(401, {'message': 'Login failed.','body': 'Incorrect username or password'})
            print(f"Unexpected ClientError during authentication: {str(e)}")
            raise e
        
        except Exception as e:
            print(f"Unexpected error during authentication: {str(e)}")
            raise

        # Get user info from database if authentication successful
        if 'AuthenticationResult' in auth_response:
            user_info = get_user_info_from_db(email)
            
            response_body = {
                'message': 'Login successful',
                'accessToken': auth_response['AuthenticationResult']['AccessToken'],
                'idToken': auth_response['AuthenticationResult']['IdToken'],
                'refreshToken': auth_response['AuthenticationResult']['RefreshToken'],
                'tokenType': auth_response['AuthenticationResult']['TokenType'],
                'expiresIn': auth_response['AuthenticationResult'].get('ExpiresIn', 3600),
                'user': user_info
            }
            
            return cors_response(200, response_body)
        
        return cors_response(401, {'error': 'Login failed'})

    except Exception as e:
        print(f"Error in main try block: {str(e)}")
        print(f"Error type: {type(e)}")
        if hasattr(e, '__traceback__'):
            import traceback
            print("Full traceback:")
            print(traceback.format_exc())
        return cors_response(500, {'error': f'An error occurred during login: {str(e)}'})

def get_user_info_from_db(email):
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_port = os.environ['DB_PORT']    
    conn = None
    
    try:
        conn = psycopg2.connect(
            host=db_host,
            user=db_user,
            password=os.environ['DB_PASSWORD'],
            port=db_port,
            
            connect_timeout=10
        )
        
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