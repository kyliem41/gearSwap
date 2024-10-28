# rabbitmq/app.py
import json
import os
import pika
import secrets
import psycopg2
from datetime import datetime, timedelta
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from psycopg2.extras import RealDictCursor
from GearSwap.rabbitmq.receive import request_password_reset

def lambda_handler(event, context):
    http_method = event['httpMethod']
    resource_path = event['resource']
    
    if resource_path == '/users/password-reset/request':
        try:
            # Get user ID from request body
            body = json.loads(event['body'])
            user_id = body.get('user_id')
            
            if not user_id:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'User ID is required'})
                }

            # Request password reset
            reset_token = request_password_reset(user_id)
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Password reset email sent successfully'
                })
            }
        except Exception as e:
            return {
                'statusCode': 500,
                'body': json.dumps({'error': f'Failed to send password reset email: {str(e)}'})
            }
    
    elif resource_path == '/users/password-reset/verify':
        try:
            # Get token and new password from request body
            body = json.loads(event['body'])
            token = body.get('token')
            new_password = body.get('new_password')
            
            if not token or not new_password:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'Token and new password are required'})
                }

            # Verify token and update password
            success = verify_reset_token(token, new_password)
            
            if success:
                return {
                    'statusCode': 200,
                    'body': json.dumps({'message': 'Password updated successfully'})
                }
            else:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'Invalid or expired token'})
                }
                
        except Exception as e:
            return {
                'statusCode': 500,
                'body': json.dumps({'error': f'Failed to reset password: {str(e)}'})
            }

    return {
        'statusCode': 400,
        'body': json.dumps('Unsupported route')
    }
    
def verify_reset_token(token, new_password):
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
            # Get token info
            cursor.execute("""
                SELECT user_id, expiration 
                FROM password_reset_tokens 
                WHERE token = %s
            """, (token,))
            
            result = cursor.fetchone()
            if not result or result[1] < datetime.utcnow():
                return False
            
            user_id = result[0]
            
            # Update password
            cursor.execute("""
                UPDATE users 
                SET password = %s 
                WHERE id = %s
            """, (new_password, user_id))
            
            # Delete used token
            cursor.execute("DELETE FROM password_reset_tokens WHERE token = %s", (token,))
            
            conn.commit()
            return True
            
    except Exception as e:
        print(f"Failed to verify reset token. Error: {str(e)}")
        return False
    finally:
        if conn:
            conn.close()