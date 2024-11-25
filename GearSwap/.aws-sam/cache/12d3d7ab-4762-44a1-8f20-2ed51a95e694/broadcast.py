# websocket/broadcast.py
import os
import json
import boto3
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime

def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT']
    )

def lambda_handler(event, context):
    """
    Broadcasts messages to connected WebSocket clients
    """
    try:
        domain = event['requestContext']['domainName']
        stage = event['requestContext']['stage']
        
        # Initialize API Gateway management client
        api_gateway = boto3.client('apigatewaymanagementapi',
            endpoint_url=f'https://{domain}/{stage}'
        )

        # Get message data
        body = json.loads(event.get('body', '{}'))
        message = body.get('message')
        user_id = body.get('userId')
        broadcast_type = body.get('type', 'all')  # 'all' or 'user'

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get active connections
                if broadcast_type == 'all':
                    cursor.execute("""
                        SELECT connection_id 
                        FROM websocket_connections
                        WHERE last_seen > NOW() - INTERVAL '1 hour'
                    """)
                else:
                    cursor.execute("""
                        SELECT connection_id 
                        FROM websocket_connections 
                        WHERE user_id = %s 
                        AND last_seen > NOW() - INTERVAL '1 hour'
                    """, (user_id,))
                
                connections = cursor.fetchall()

        # Send message to each connection
        timestamp = datetime.now().isoformat()
        message_data = {
            'message': message,
            'timestamp': timestamp,
            'type': broadcast_type
        }

        for conn in connections:
            try:
                api_gateway.post_to_connection(
                    ConnectionId=conn['connection_id'],
                    Data=json.dumps(message_data)
                )
            except Exception as e:
                if 'GoneException' in str(e):
                    # Connection is no longer valid, remove it
                    with get_db_connection() as conn:
                        with conn.cursor() as cursor:
                            cursor.execute("""
                                DELETE FROM websocket_connections 
                                WHERE connection_id = %s
                            """, (conn['connection_id'],))
                            conn.commit()
                else:
                    print(f"Error sending message to connection {conn['connection_id']}: {str(e)}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Message broadcast successfully',
                'recipients': len(connections)
            })
        }
    except Exception as e:
        print(f"Broadcast error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }