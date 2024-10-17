import os
import psycopg2
from psycopg2.extras import RealDictCursor

def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT'],
    )

def lambda_handler(event, context):
    if event['triggerSource'] == 'UserMigration_Authentication':
        return authenticate(event)
    elif event['triggerSource'] == 'UserMigration_ForgotPassword':
        return migrate_user(event)

def authenticate(event):
    username_or_email = event['userName']

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Check if the input is an email or username
                if '@' in username_or_email:
                    cursor.execute("SELECT * FROM users WHERE email = %s", (username_or_email,))
                else:
                    cursor.execute("SELECT * FROM users WHERE username = %s", (username_or_email,))
                
                user = cursor.fetchone()

                if user:
                    # User exists in our database, allow Cognito to handle the authentication
                    event['response'] = {
                        'userAttributes': {
                            'email': user['email'],
                            'email_verified': 'true',
                            'given_name': user['firstname'],
                            'family_name': user['lastname']
                        }
                    }
                    return event

                raise Exception('User not found in database')

    except Exception as e:
        print(f"Authentication failed: {str(e)}")
        raise Exception('User authentication failed')

def migrate_user(event):
    username_or_email = event['userName']

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Check if the input is an email or username
                if '@' in username_or_email:
                    cursor.execute("SELECT * FROM users WHERE email = %s", (username_or_email,))
                else:
                    cursor.execute("SELECT * FROM users WHERE username = %s", (username_or_email,))
                
                user = cursor.fetchone()

                if user:
                    event['response'] = {
                        'userAttributes': {
                            'email': user['email'],
                            'email_verified': 'true',
                            'given_name': user['firstname'],
                            'family_name': user['lastname']
                        }
                    }
                    return event

                raise Exception('User does not exist')

    except Exception as e:
        print(f"User migration failed: {str(e)}")
        raise Exception('User migration failed')