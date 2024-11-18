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

async def lambda_handler(event, context):
    try:
        connection_id = event['requestContext']['connectionId']
        domain = event['requestContext']['domainName']
        stage = event['requestContext']['stage']
        
        body = json.loads(event['body'])
        message = body.get('message')
        message_type = body.get('type', 'conversation')

        conn = get_db_connection()
        recommender = FashionGPTRecommender(conn)

        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("""
                    SELECT user_id 
                    FROM websocket_connections 
                    WHERE connection_id = %s
                """, (connection_id,))
                result = cursor.fetchone()
                if not result:
                    raise Exception('Connection not found')
                user_id = result['user_id']
                
                loop = asyncio.get_event_loop()
                response = loop.run_until_complete(recommender.get_recommendation(
                    user_id=user_id,
                    request_type=message_type,
                    message=message,
                    context=body.get('context', [])
                ))

                # Initialize API Gateway client
                api_client = boto3.client('apigatewaymanagementapi',
                    endpoint_url=f'https://{domain}/{stage}'
                )

                api_client.post_to_connection(
                    ConnectionId=connection_id,
                    Data=json.dumps({
                        'type': 'stylist_response',
                        'response': response['recommendation'],
                        'model': response.get('context', {}).get('model_used', 'unknown'),
                        'timestamp': datetime.now().isoformat()
                    })
                )
                
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

            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'Message processed successfully'})
            }

        finally:
            conn.close()

    except Exception as e:
        print(f"Message handling error: {str(e)}")
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }