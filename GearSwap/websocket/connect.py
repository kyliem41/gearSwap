# websocket/connect.py
import os
import json
import psycopg2
from psycopg2.extras import RealDictCursor
import jwt
from jwt.algorithms import RSAAlgorithm
import requests
import boto3

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
        
        # Verify JWT token
        user_data = verify_token(token)
        user_id = user_data['sub']

        # Store connection in PostgreSQL
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO websocket_connections (connection_id, user_id)
                    VALUES (%s, %s)
                    ON CONFLICT (connection_id) 
                    DO UPDATE SET user_id = EXCLUDED.user_id, last_seen = CURRENT_TIMESTAMP
                """, (connection_id, user_id))
                conn.commit()

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Connected'})
        }
    except Exception as e:
        print(f"Connection error: {str(e)}")
        return {
            'statusCode': 401,
            'body': json.dumps({'error': str(e)})
        }