# websocket/message.py
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
        
        # Initialize API Gateway management client
        api_gateway = boto3.client('apigatewaymanagementapi',
            endpoint_url=f'https://{domain}/{stage}'
        )

        # Get DB connection and create recommender
        conn = get_db_connection()
        recommender = FashionGPTRecommender(conn)

        try:
            # Get user ID from connection
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

                # Update last seen timestamp
                cursor.execute("""
                    UPDATE websocket_connections 
                    SET last_seen = CURRENT_TIMESTAMP 
                    WHERE connection_id = %s
                """, (connection_id,))

                # Parse message
                body = json.loads(event['body'])
                message = body.get('message')
                message_type = body.get('type', 'conversation')

                # Get AI recommendation
                response = await recommender.get_recommendation(
                    user_id=user_id,
                    request_type=message_type,
                    message=message,
                    context=body.get('context', [])
                )

                # Send response through WebSocket
                api_gateway.post_to_connection(
                    ConnectionId=connection_id,
                    Data=json.dumps({
                        'type': 'stylist_response',
                        'response': response['recommendation'],
                        'model': response.get('context', {}).get('model_used', 'unknown'),
                        'timestamp': datetime.now().isoformat()
                    })
                )

                # Log the conversation
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
                'body': json.dumps({'message': 'Message processed'})
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