import json
import os
import boto3
import psycopg2
from psycopg2.extras import RealDictCursor
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    # Parse the incoming request body
    print('test1')
    try:
        body = json.loads(event['body'])
        email = body['email']
        password = body['password']
    except (KeyError, json.JSONDecodeError):
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid request body')
        }

    print('test2')
    # Initialize Cognito client
    cognito_client = boto3.client('cognito-idp')
    user_pool_id = os.environ['COGNITO_USER_POOL_ID']
    client_id = os.environ['COGNITO_CLIENT_ID']
    
    print(cognito_client)
    print(user_pool_id)
    print(client_id)

    try:
        # Attempt to authenticate the user with Cognito
        response = cognito_client.admin_initiate_auth(
            UserPoolId=user_pool_id,
            ClientId=client_id,
            AuthFlow='ADMIN_USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': email,
                'PASSWORD': password
            }
        )
        print('test3')

        # If authentication is successful, get the user's information from the database
        if 'AuthenticationResult' in response:
            user_info = get_user_info_from_db(email)
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Login successful',
                    'token': response['AuthenticationResult']['AccessToken'],
                    'user': user_info
                })
            }
        else:
            return {
                'statusCode': 401,
                'body': json.dumps('Login failed')
            }
            print('test4')

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'NotAuthorizedException':
            return {
                'statusCode': 401,
                'body': json.dumps('Incorrect username or password')
            }
        elif error_code == 'UserNotFoundException':
            return {
                'statusCode': 404,
                'body': json.dumps('User not found')
            }
        else:
            print(f"Unexpected error: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps('An error occurred during login')
            }
            print('test5')

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