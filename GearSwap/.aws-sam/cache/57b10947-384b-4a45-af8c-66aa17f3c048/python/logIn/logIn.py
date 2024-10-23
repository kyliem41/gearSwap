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
    try:
        # Parse request body
        body = json.loads(event['body'])
        email = body['email']
        password = body['password']
    except (KeyError, json.JSONDecodeError):
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid request body')
        }

    # Initialize Cognito client
    cognito_client = boto3.client('cognito-idp')
    user_pool_id = os.environ['COGNITO_USER_POOL_ID']
    client_id = os.environ['COGNITO_CLIENT_ID']

    try:
        # Verify user exists
        try:
            user = cognito_client.admin_get_user(
                UserPoolId=user_pool_id,
                Username=email
            )
        except cognito_client.exceptions.UserNotFoundException:
            return {
                'statusCode': 404,
                'body': json.dumps('User not found')
            }

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
        except ClientError as e:
            if e.response['Error']['Code'] == 'NotAuthorizedException':
                return {
                    'statusCode': 401,
                    'body': json.dumps('Incorrect username or password')
                }
            raise e

        # Get user info from database if authentication successful
        if 'AuthenticationResult' in auth_response:
            user_info = get_user_info_from_db(email)
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Login successful',
                    'accessToken': auth_response['AuthenticationResult']['AccessToken'],
                    'idToken': auth_response['AuthenticationResult']['IdToken'],
                    'refreshToken': auth_response['AuthenticationResult']['RefreshToken'],
                    'tokenType': auth_response['AuthenticationResult']['TokenType'],
                    'expiresIn': auth_response['AuthenticationResult'].get('ExpiresIn', 3600),
                    'user': user_info
                }, cls=DateTimeEncoder)
            }
        
        return {
            'statusCode': 401,
            'body': json.dumps('Login failed')
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'An error occurred during login: {str(e)}')
        }

def get_user_info_from_db(email):
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
        print('test6')
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            query = "SELECT id, firstName, lastName, username, email, profileInfo, joinDate, likeCount FROM users WHERE email = %s"
            cursor.execute(query, (email,))
            user = cursor.fetchone()

        return user

    except Exception as e:
        print(f"Database error: {str(e)}")
        return None
    finally:
        if conn:
            conn.close()