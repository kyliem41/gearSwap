# websocket/connect.py
import os
import json
import psycopg2
from psycopg2.extras import RealDictCursor
import jwt
from jwt.algorithms import RSAAlgorithm
import requests
import boto3
from jwt import decode

def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT']
    )

def verify_token(token):
    if not token:
        raise Exception('No token provided')

    headers = jwt.get_unverified_header(token)
    kid = headers['kid']

    # Get Cognito public keys
    url = f'https://cognito-idp.{os.environ["AWS_REGION"]}.amazonaws.com/{os.environ["COGNITO_USER_POOL_ID"]}/.well-known/jwks.json'
    response = requests.get(url)
    keys = response.json()['keys']

    # Find matching public key
    public_key = None
    for key in keys:
        if key['kid'] == kid:
            public_key = RSAAlgorithm.from_jwk(json.dumps(key))
            break

    if not public_key:
        raise Exception('Public key not found')

    try:
        payload = jwt.decode(
            token,
            public_key,
            algorithms=['RS256'],
            audience=os.environ['COGNITO_CLIENT_ID']
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise Exception('Token has expired')
    except jwt.InvalidTokenError:
        raise Exception('Invalid token')

def lambda_handler(event, context):
    try:
        connection_id = event['requestContext']['connectionId']
        token = event['queryStringParameters'].get('token')
        
        if not token:
            raise ValueError("Token is required")

        # Verify JWT token
        user_data = verify_token(token)
        email = user_data.get('email')  # Assuming email is in the token payload
        
        if not email:
            raise ValueError("Invalid token payload")

        # Get user ID from database using email
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                # First get the user ID using the email from token
                cursor.execute("""
                    SELECT id FROM users 
                    WHERE email = %s
                """, (email,))
                
                result = cursor.fetchone()
                if not result:
                    raise ValueError("User not found")
                
                user_id = result[0]  # This will be an integer from the SERIAL column
                
                # Now store the connection with the correct user ID
                cursor.execute("""
                    INSERT INTO websocket_connections (connection_id, user_id)
                    VALUES (%s, %s)
                    ON CONFLICT (connection_id) 
                    DO UPDATE SET user_id = EXCLUDED.user_id, last_seen = CURRENT_TIMESTAMP
                """, (connection_id, str(user_id)))  # Convert to string since user_id column is VARCHAR
                
                conn.commit()

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Connected',
                'userId': user_id
            })
        }
    except ValueError as ve:
        print(f"Validation error: {str(ve)}")
        return {
            'statusCode': 401,
            'body': json.dumps({'error': str(ve)})
        }
    except Exception as e:
        print(f"Connection error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }