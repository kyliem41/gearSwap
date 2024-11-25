# websocket/disconnect.py
import os
import json
import psycopg2

def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT']
    )

def lambda_handler(event, context):
    try:
        connection_id = event['requestContext']['connectionId']
        
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    DELETE FROM websocket_connections
                    WHERE connection_id = %s
                """, (connection_id,))
                conn.commit()

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Disconnected'})
        }
    except Exception as e:
        print(f"Disconnection error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }