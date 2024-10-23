import json
import os
import boto3
import psycopg2
from psycopg2.extras import RealDictCursor
from botocore.exceptions import ClientError
from datetime import datetime

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        email = body['email']
        password = body['password']
    except (KeyError, json.JSONDecodeError):
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid request body')
        }

    cognito_client = boto3.client('cognito-idp')
    user_pool_id = os.environ['COGNITO_USER_POOL_ID']
    client_id = os.environ['COGNITO_CLIENT_ID']

    try:
        # Attempt authentication
        auth_response = cognito_client.admin_initiate_auth(
            UserPoolId=user_pool_id,
            ClientId=client_id,
            AuthFlow='ADMIN_USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': email,  # Use email for authentication
                'PASSWORD': password
            }
        )

        if 'AuthenticationResult' in auth_response:
            user_info = get_user_info_from_db(email)
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Login successful',
                    'token': auth_response['AuthenticationResult']['AccessToken'],
                    'idToken': auth_response['AuthenticationResult'].get('IdToken'),
                    'refreshToken': auth_response['AuthenticationResult'].get('RefreshToken'),
                    'user': user_info
                }, cls=DateTimeEncoder)
            }
        else:
            return {
                'statusCode': 401,
                'body': json.dumps('Login failed')
            }

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        print(f"Cognito error: {error_code} - {error_message}")
        
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
            return {
                'statusCode': 500,
                'body': json.dumps(f'An error occurred during login: {error_message}')
            }