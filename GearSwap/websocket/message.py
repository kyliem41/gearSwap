# websocket/message.py
import asyncio
import os
import json
import boto3
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime
import sys
from typing import Dict, Any
import traceback

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from styler import FashionGPTRecommender

def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT']
    )

def lambda_handler(event, context):
    print("Message Lambda triggered with event:", json.dumps(event))
    try:
        connection_id = event['requestContext']['connectionId']
        domain = event['requestContext']['domainName']
        stage = event['requestContext']['stage']
        
        print(f"Processing message for connection: {connection_id}")
        
        body = json.loads(event['body'])
        message = body.get('message')
        message_type = body.get('type', 'conversation')
        
        print(f"Parsed message: {message}, type: {message_type}")

        conn = get_db_connection()
        print("Database connection established")
        
        recommender = FashionGPTRecommender(conn)
        print("Recommender initialized")

        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("""
                    SELECT user_id 
                    FROM websocket_connections 
                    WHERE connection_id = %s
                """, (connection_id,))
                result = cursor.fetchone()
                if not result:
                    print(f"No connection found for connection_id: {connection_id}")
                    raise Exception('Connection not found')
                user_id = result['user_id']
                print(f"Found user_id: {user_id}")
                
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                try:
                    print("Getting AI recommendation...")
                    response = loop.run_until_complete(recommender.get_recommendation(
                        user_id=user_id,
                        request_type=message_type,
                        message=message,
                        context=body.get('context', [])
                    ))
                    print("Got AI recommendation:", json.dumps(response))
                finally:
                    loop.close()

                api_endpoint = f'https://{domain}/{stage}'
                print(f"API Gateway endpoint: {api_endpoint}")
                
                api_client = boto3.client('apigatewaymanagementapi',
                    endpoint_url=api_endpoint
                )

                response_data = {
                    'type': 'stylist_response',
                    'response': response['recommendation'],
                    'model': response.get('context', {}).get('model_used', 'unknown'),
                    'timestamp': datetime.now().isoformat()
                }
                
                print(f"Sending response data: {json.dumps(response_data)}")

                api_client.post_to_connection(
                    ConnectionId=connection_id,
                    Data=json.dumps(response_data)
                )
                print("Response sent successfully")
                
                print("Logging conversation...")
                cursor.execute("""
                    INSERT INTO conversation_logs 
                    (user_id, user_message, ai_response, request_type, timestamp, model_used)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (
                    user_id,
                    message,
                    response['recommendation'],
                    message_type,
                    datetime.now(),
                    response.get('context', {}).get('model_used', 'unknown')
                ))
                conn.commit()
                print("Conversation logged successfully")

            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'Message processed successfully'})
            }

        finally:
            conn.close()
            print("Database connection closed")

    except Exception as e:
        print(f"Message handling error: {str(e)}")
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }