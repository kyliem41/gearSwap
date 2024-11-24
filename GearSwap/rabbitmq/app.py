import base64
import json
import os
import traceback
import psycopg2
from datetime import datetime, timedelta
import secrets
from psycopg2.extras import RealDictCursor
from send import EmailService, EmailProvider

def cors_response(status_code, body, content_type='application/json'):
    headers = {
        'Content-Type': content_type,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE'
    }
    
    if content_type == 'application/json':
        body = json.dumps(body, default=str)
        is_base64 = False
    else:
        is_base64 = True
    
    return {
        'statusCode': status_code,
        'headers': headers,
        'body': body,
        'isBase64Encoded': is_base64
    }
    
def parse_body(event):
    """Helper function to parse request body handling both base64 and regular JSON"""
    try:
        if event.get('isBase64Encoded', False):
            decoded_body = base64.b64decode(event['body']).decode('utf-8')
            try:
                return json.loads(decoded_body)
            except json.JSONDecodeError:
                return decoded_body
        elif isinstance(event.get('body'), dict):
            return event['body']
        elif isinstance(event.get('body'), str):
            return json.loads(event['body'])
        return {}
    except Exception as e:
        print(f"Error parsing body: {str(e)}")
        raise ValueError(f"Invalid request body: {str(e)}")

def lambda_handler(event, context):
    if event['httpMethod'] == 'OPTIONS':
        return cors_response(200, {'message': 'OK'})

    try:
        print("Received event:", json.dumps(event))
        
        if event['resource'] == '/users/password-reset/request':
            return handle_reset_request(event)
        elif event['resource'] == '/users/password-reset/verify':
            return handle_reset_verification(event)
        else:
            return cors_response(400, {'error': 'Invalid endpoint'})

    except Exception as e:
        print("Error:", str(e))
        print("Traceback:", traceback.format_exc())
        return cors_response(500, {
            'error': 'Internal server error',
            'details': str(e)
        })

def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT'],
        
        connect_timeout=5
    )

def handle_reset_request(event):
    try:
        try:
            body = parse_body(event)
        except ValueError as e:
            return cors_response(400, {'error': str(e)})
        
        email = body.get('email')

        if not email:
            return cors_response(400, {'error': 'Email is required'})

        conn = get_db_connection()
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            # Check if user exists
            cursor.execute(
                "SELECT id, email FROM users WHERE email = %s",
                (email,)
            )
            user = cursor.fetchone()

            if not user:
                return cors_response(404, {'error': 'No account found with this email address'})

            # Generate and store reset token
            reset_token = secrets.token_urlsafe(32)
            expiration = datetime.utcnow() + timedelta(hours=24)

            cursor.execute("""
                INSERT INTO password_reset_tokens (userId, token, expiration)
                VALUES (%s, %s, %s)
                ON CONFLICT (userId)
                DO UPDATE SET 
                    token = EXCLUDED.token,
                    expiration = EXCLUDED.expiration,
                    created_at = CURRENT_TIMESTAMP
                RETURNING token;
            """, (user['id'], reset_token, expiration))
            
            conn.commit()

            # Send reset email
            try:
                email_service = EmailService(EmailProvider.SES)
                email_service.send_reset_email(
                    to_email=email,
                    reset_token=reset_token,
                    userId=str(user['id'])
                )
            except Exception as e:
                print(f"Failed to send reset email: {str(e)}")
                return cors_response(500, {'error': 'Failed to send reset email'})

            return cors_response(200, {'message': 'Password reset instructions sent'})

    except Exception as e:
        print(f"Error in reset request: {str(e)}")
        return cors_response(500, {'error': str(e)})

    finally:
        if conn:
            conn.close()

def handle_reset_verification(event):
    try:
        try:
            body = parse_body(event)
        except ValueError as e:
            return cors_response(400, {'error': str(e)})
        
        token = body.get('token')
        new_password = body.get('new_password')

        if not token or not new_password:
            return cors_response(400, {'error': 'Token and new password are required'})

        conn = get_db_connection()
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            # Verify token and get user
            cursor.execute("""
                SELECT rt.userId, rt.expiration, u.email 
                FROM password_reset_tokens rt
                JOIN users u ON u.id = rt.userId
                WHERE rt.token = %s
            """, (token,))
            
            result = cursor.fetchone()
            
            if not result:
                return cors_response(400, {'error': 'Invalid reset token'})

            if result['expiration'] < datetime.utcnow():
                return cors_response(400, {'error': 'Reset token has expired'})

            # Update password
            cursor.execute("""
                UPDATE users 
                SET password = %s 
                WHERE id = %s
            """, (new_password, result['userId']))

            # Delete used token
            cursor.execute(
                "DELETE FROM password_reset_tokens WHERE userId = %s",
                (result['userId'],)
            )

            conn.commit()

            return cors_response(200, {'message': 'Password updated successfully'})

    except Exception as e:
        print(f"Error in reset verification: {str(e)}")
        return cors_response(500, {'error': str(e)})

    finally:
        if conn:
            conn.close()