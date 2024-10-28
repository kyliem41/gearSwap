import pika
import json
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import psycopg2
from psycopg2.extras import RealDictCursor
import os

from GearSwap.rabbitmq.receive import get_rabbitmq_connection

def get_user_email(user_id):
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
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            get_query = "SELECT email FROM users WHERE id = %s"
            cursor.execute(get_query, (user_id,))
            user = cursor.fetchone()
            
            if user:
                return user['email']
            return None
            
    except Exception as e:
        print(f"Failed to get user email. Error: {str(e)}")
        return None
    finally:
        if conn:
            conn.close()

def callback(ch, method, properties, body):
    # Parse the message
    message = json.loads(body)
    user_email = get_user_email(message['user_id'])
    
    if user_email:
        send_password_reset(
            to_email=user_email,
            reset_token=message['reset_token']
        )
        print(f" [x] Sent password reset email to {user_email}")
    else:
        print(f" [x] Failed to find email for user {message['user_id']}")
    
    ch.basic_ack(delivery_tag=method.delivery_tag)

def send_password_reset(to_email, reset_token):
    # Create message
    msg = MIMEMultipart()
    msg['Subject'] = "Password Reset Request"
    msg['To'] = to_email

    # Email body
    body = f"""
    Hello,

    You have requested to reset your password. Click the link below to reset it:
    
    https://your-frontend-url/reset-password?token={reset_token}
    
    If you didn't request this, please ignore this email.

    Best regards,
    GearSwap Team
    """
    
    msg.attach(MIMEText(body, 'plain'))

    # Send email using your preferred email service
    # Implementation will depend on your email provider
    print(f"Would send email to {to_email} with reset token {reset_token}")
    # Add your email sending implementation here

def main():
    connection = get_rabbitmq_connection()
    channel = connection.channel()

    # Declare queue
    channel.queue_declare(queue='password_reset')

    # Set up consumer
    channel.basic_consume(
        queue='password_reset',
        on_message_callback=callback,
        auto_ack=True
    )

    print(' [*] Waiting for password reset messages. To exit press CTRL+C')
    channel.start_consuming()

if __name__ == '__main__':
    main()