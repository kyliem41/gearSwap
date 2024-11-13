import json
import os
import base64
import psycopg2
from psycopg2.extras import RealDictCursor

DB_HOST = os.environ['DB_HOST']
DB_USER = os.environ['DB_USER']
DB_PASSWORD = os.environ['DB_PASSWORD']
DB_PORT = os.environ['DB_PORT']

# Constants
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_CONTENT_TYPES = {
    'image/jpeg',
    'image/png'
}

def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT'],
        
        connect_timeout=5
    )

def lambda_handler(event, context):
    if event['httpMethod'] == 'OPTIONS':
        return response(200, 'OK')
        
    conn = get_db_connection()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            if event['httpMethod'] == 'GET':
                return get_profile_picture(event, cur)
            elif event['httpMethod'] == 'PUT':
                return update_profile_picture(event, cur)
            elif event['httpMethod'] == 'DELETE':
                return delete_profile_picture(event, cur)
            else:
                return response(405, {'error': 'Method not allowed'})
    finally:
        conn.close()

def get_profile_picture(event, cur):
    try:
        user_id = event['pathParameters']['id']
        
        # Fetch the image data
        cur.execute("""
            SELECT profile_picture, profile_picture_content_type
            FROM "user"
            WHERE id = %s
        """, (user_id,))
        
        result = cur.fetchone()
        if not result or not result['profile_picture']:
            return response(404, {'error': 'Profile picture not found'})

        # Convert image data to bytes if needed
        image_data = result['profile_picture']
        if isinstance(image_data, memoryview):
            image_data = image_data.tobytes()
        
        # Return the image directly with proper headers
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': result['profile_picture_content_type'],
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'OPTIONS,GET,PUT,DELETE'
            },
            'body': base64.b64encode(image_data).decode('utf-8'),
            'isBase64Encoded': True
        }
        
    except Exception as e:
        print(f"Error retrieving profile picture: {str(e)}")
        return response(500, {'error': 'Internal server error'})

def update_profile_picture(event, cur):
    try:
        user_id = event['pathParameters']['id']
        
        # More robust content type checking
        headers = event.get('headers', {})
        # Convert all header keys to lowercase for case-insensitive comparison
        headers = {k.lower(): v for k, v in headers.items()}
        
        # Try multiple possible header keys
        content_type = (
            headers.get('content-type') or 
            headers.get('x-content-type') or 
            ''
        )
        
        print("All headers:", headers)  # Debug print
        print("Found content-type:", content_type)  # Debug print
        print("Is base64 encoded:", event.get('isBase64Encoded', False))
        
        # Validate content type
        if not content_type:
            return response(400, {'error': 'Content-Type header is required'})
            
        if content_type not in ALLOWED_CONTENT_TYPES:
            return response(400, {
                'error': f'Invalid content type. Allowed types: {", ".join(ALLOWED_CONTENT_TYPES)}'
            })
        
        # Get body content
        body = event.get('body', '')
        
        if not body:
            return response(400, {'error': 'No image data provided'})
        
        try:
            # If the content is base64 encoded by API Gateway
            if event.get('isBase64Encoded', False):
                image_data = base64.b64decode(body)
            else:
                # Handle raw binary data
                try:
                    # First, try to handle it as a string that needs to be encoded to bytes
                    if isinstance(body, str):
                        image_data = body.encode('utf-8')
                    else:
                        image_data = body
                        
                    # Verify we have valid image data
                    if content_type == 'image/png':
                        png_header = b'\x89PNG\r\n\x1a\n'
                        if not image_data.startswith(png_header):
                            return response(400, {
                                'error': 'Invalid PNG image data',
                                'help': 'Please ensure you are sending a valid PNG file through binary body in Postman'
                            })
                    elif content_type == 'image/jpeg':
                        jpeg_header = b'\xff\xd8\xff'
                        if not image_data.startswith(jpeg_header):
                            return response(400, {
                                'error': 'Invalid JPEG image data',
                                'help': 'Please ensure you are sending a valid JPEG file through binary body in Postman'
                            })
                            
                except Exception as e:
                    print(f"Error processing binary data: {str(e)}")
                    return response(400, {
                        'error': 'Could not process image data',
                        'details': str(e),
                        'help': 'Please ensure in Postman:\n1. Body is set to "binary"\n2. A valid image file is selected\n3. Content-Type header matches your image type'
                    })
            
            print(f"Processed image data length: {len(image_data)} bytes")
            print(f"First few bytes (hex): {image_data[:8].hex()}")
            
            # Update the profile picture in the database
            cur.execute("""
                UPDATE "user"
                SET profile_picture = %s,
                    profile_picture_content_type = %s,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
                RETURNING id
            """, (psycopg2.Binary(image_data), content_type, user_id))
            
            updated_user = cur.fetchone()
            if not updated_user:
                return response(404, {'error': 'User not found'})
                
            cur.connection.commit()
            return response(200, {'message': 'Profile picture updated successfully'})
            
        except Exception as e:
            print(f"Error processing image: {str(e)}")
            import traceback
            print("Traceback:", traceback.format_exc())
            return response(400, {
                'error': 'Invalid image data format',
                'details': str(e),
                'help': 'Please check your Postman settings:\n1. Body should be set to "binary"\n2. Content-Type should match your image type\n3. A valid image file should be selected'
            })
            
    except Exception as e:
        print(f"General error: {str(e)}")
        import traceback
        print("Traceback:", traceback.format_exc())
        return response(500, {'error': 'Internal server error', 'details': str(e)})

def delete_profile_picture(event, cur):
    try:
        user_id = event['pathParameters']['id']
        
        cur.execute("""
            UPDATE "user"
            SET profile_picture = NULL,
                profile_picture_content_type = NULL,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
            RETURNING id
        """, (user_id,))
        
        updated_user = cur.fetchone()
        if not updated_user:
            return response(404, {'error': 'User not found'})
            
        cur.connection.commit()
        return response(200, {'message': 'Profile picture deleted successfully'})
        
    except Exception as e:
        cur.connection.rollback()
        print(f"Error deleting profile picture: {str(e)}")
        return response(500, {'error': 'Internal server error'})

def response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'OPTIONS,GET,PUT,DELETE'
        },
        'body': json.dumps(body) if isinstance(body, (dict, str)) else body
    }