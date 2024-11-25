import os
import ssl
import traceback
import pika
import json
import secrets
import psycopg2
from datetime import datetime, timedelta

def get_rabbitmq_connection():
    try:
        url = os.environ['RABBITMQ_HOST']
        print(f"Connecting to RabbitMQ at: {url}")

        ssl_context = ssl.create_default_context()
        ssl_context.check_hostname = False
        ssl_context.verify_mode = ssl.CERT_NONE

        parameters = pika.URLParameters(url)
        parameters.ssl_options = pika.SSLOptions(ssl_context)
        parameters.credentials = pika.PlainCredentials(
            os.environ['RABBITMQ_USER'],
            os.environ['RABBITMQ_PASSWORD']
        )

        connection = pika.BlockingConnection(parameters)
        print("Successfully connected to RabbitMQ")
        return connection
    except Exception as e:
        print(f"Failed to connect to RabbitMQ: {str(e)}")
        print("Traceback:", traceback.format_exc())
        raise

def request_password_reset(userId):
    reset_token = secrets.token_urlsafe(32)
    expiration = datetime.utcnow() + timedelta(hours=24)
    
    store_reset_token(userId, reset_token, expiration)
    
    connection = get_rabbitmq_connection()
    channel = connection.channel()
    channel.queue_declare(queue='password_reset')

    message = {
        'userId': userId,
        'reset_token': reset_token
    }

    channel.basic_publish(
        exchange='',
        routing_key='password_reset',
        body=json.dumps(message)
    )

    connection.close()
    return reset_token

def store_reset_token(userId, token, expiration):
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
        
        with conn.cursor() as cursor:
            # You'll need to create this table in your database
            insert_query = """
            INSERT INTO password_reset_tokens (userId, token, expiration)
            VALUES (%s, %s, %s)
            ON CONFLICT (userId) 
            DO UPDATE SET token = EXCLUDED.token, expiration = EXCLUDED.expiration;
            """
            cursor.execute(insert_query, (userId, token, expiration))
            conn.commit()
            
    except Exception as e:
        print(f"Failed to store reset token. Error: {str(e)}")
    finally:
        if conn:
            conn.close()