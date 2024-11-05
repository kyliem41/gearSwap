import json
import os
import traceback
import psycopg2
from datetime import datetime, timedelta
import secrets
from psycopg2.extras import RealDictCursor
from send import EmailService, EmailProvider

def lambda_handler(event, context):
    try:
        print("Received event:", json.dumps(event))
        
        if event['resource'] == '/users/password-reset/request':
            return handle_reset_request(event)
        elif event['resource'] == '/users/password-reset/verify':
            return handle_reset_verification(event)
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Invalid endpoint'})
            }
    except Exception as e:
        print("Error:", str(e))
        print("Traceback:", traceback.format_exc())
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'details': str(e)
            })
        }

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
        body = json.loads(event['body'])
        email = body.get('email')

        if not email:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Email is required'})
            }

        conn = get_db_connection()
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            # Check if user exists
            cursor.execute(
                "SELECT id, email FROM users WHERE email = %s",
                (email,)
            )
            user = cursor.fetchone()

            if not user:
                return {
                    'statusCode': 404,
                    'body': json.dumps({'error': 'No account found with this email address'})
                }

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
                return {
                    'statusCode': 500,
                    'body': json.dumps({'error': 'Failed to send reset email'})
                }

            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'Password reset instructions sent'})
            }

    except Exception as e:
        print(f"Error in reset request: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
    finally:
        if conn:
            conn.close()

def handle_reset_verification(event):
    try:
        body = json.loads(event['body'])
        token = body.get('token')
        new_password = body.get('new_password')

        if not token or not new_password:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Token and new password are required'})
            }

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
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'Invalid reset token'})
                }

            if result['expiration'] < datetime.utcnow():
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'Reset token has expired'})
                }

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

            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'Password updated successfully'})
            }

    except Exception as e:
        print(f"Error in reset verification: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
    finally:
        if conn:
            conn.close()