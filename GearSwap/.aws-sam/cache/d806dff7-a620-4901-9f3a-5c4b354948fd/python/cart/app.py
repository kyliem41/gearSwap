import base64
import jwt
import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime
import boto3
import requests
from jwt.algorithms import RSAAlgorithm

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
    
    http_method = event['httpMethod']
    resource_path = event['resource']
    
    try:
        auth_header = event.get('headers', {}).get('Authorization')
        if not auth_header:
            return cors_response(401, {'error': 'No authorization header'})

        # Extract token from Bearer authentication
        token = auth_header.split(' ')[-1]
        verify_token(token)
    except Exception as e:
        return cors_response(401, {'error': f'Authentication failed: {str(e)}'})

    if resource_path == '/cart/{Id}':
        user_id = event['pathParameters']['Id']
        if http_method == 'POST':
            return add_to_cart(event, user_id)
        elif http_method == 'GET':
            return get_cart(user_id)
        elif http_method == 'PUT':
            return update_cart_item(event, user_id)
        elif http_method == 'DELETE':
            return remove_from_cart(event, user_id)

    return cors_response(400, {'error': 'Unsupported route'})
    
########################
#AUTH
def verify_token(token):
    # Get the JWT token from the Authorization header
    if not token:
        raise Exception('No token provided')

    region = boto3.session.Session().region_name
    
    # Get the JWT kid (key ID)
    headers = jwt.get_unverified_header(token)
    kid = headers['kid']

    # Get the public keys from Cognito
    url = f'https://cognito-idp.{region}.amazonaws.com/{os.environ["COGNITO_USER_POOL_ID"]}/.well-known/jwks.json'
    response = requests.get(url)
    keys = response.json()['keys']

    # Find the correct public key
    public_key = None
    for key in keys:
        if key['kid'] == kid:
            public_key = RSAAlgorithm.from_jwk(json.dumps(key))
            break

    if not public_key:
        raise Exception('Public key not found')

    # Verify the token
    try:
        payload = jwt.decode(
            token,
            public_key,
            algorithms=['RS256'],
            audience=os.environ['COGNITO_CLIENT_ID'],
            options={"verify_exp": True}
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise Exception('Token has expired')
    except jwt.InvalidTokenError:
        raise Exception('Invalid token')

########################
def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT'],
        
        connect_timeout=5
    )

########################
def check_post_ownership(cursor, user_id, post_id):
    """Helper function to check if a user owns a post"""
    cursor.execute("SELECT userid FROM posts WHERE id = %s", (post_id,))
    post = cursor.fetchone()
    if not post:
        raise ValueError("Post not found")
    return str(post['userid']) == str(user_id)

##################
def add_to_cart(event, user_id):
    try:
        try:
            body = parse_body(event)
        except ValueError as e:
            return cors_response(400, {'error': str(e)})
        
        post_id = body['postId']
        quantity = body.get('quantity', 1)

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # First check if post exists and get post owner
                cursor.execute("""
                    SELECT userId, isSold 
                    FROM posts 
                    WHERE id = %s
                """, (post_id,))
                post = cursor.fetchone()
                
                if not post:
                    return cors_response(404, {
                        "error": "Post not found"
                    })

                # Check if user is trying to add their own post
                if str(post['userid']) == str(user_id):
                    return cors_response(400, {
                        "error": "You cannot add your own items to cart"
                    })

                # Check if post is already sold
                if post.get('issold'):
                    return cors_response(400, {
                        "error": "This item has already been sold"
                    })

                # Check if item is already in cart
                cursor.execute(
                    "SELECT * FROM cart WHERE userId = %s AND postId = %s", 
                    (user_id, post_id)
                )
                existing_item = cursor.fetchone()

                try:
                    cursor.execute("BEGIN")
                    
                    if existing_item:
                        cursor.execute("""
                            UPDATE cart 
                            SET quantity = quantity + %s 
                            WHERE userId = %s AND postId = %s 
                            RETURNING *
                            """, (quantity, user_id, post_id))
                    else:
                        cursor.execute("""
                            INSERT INTO cart (userId, postId, quantity) 
                            VALUES (%s, %s, %s) 
                            RETURNING *
                            """, (user_id, post_id, quantity))

                    new_item = cursor.fetchone()
                    conn.commit()

                    return cors_response(200, {
                        "message": "Item added to cart successfully",
                        "item": new_item
                    })
                    
                except Exception as e:
                    conn.rollback()
                    raise e

    except KeyError as e:
        return cors_response(400, {"error": f"Missing required field: {str(e)}"})
    except ValueError as e:
        return cors_response(400, {"error": str(e)})
    except Exception as e:
        print(f"Failed to add item to cart. Error: {str(e)}")
        return cors_response(500, {"error": f"Error adding item to cart: {str(e)}"})

########################
def get_cart(user_id):
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("""
                    SELECT c.*,
                        p.*,
                        ARRAY_AGG(
                            json_build_object(
                                'id', pi.id,
                                'content_type', pi.content_type,
                                'data', encode(pi.image_data, 'base64')
                            )
                        ) as images
                    FROM cart c
                    JOIN posts p ON c.postId = p.id
                    LEFT JOIN post_images pi ON p.id = pi.post_id
                    WHERE c.userId = %s
                    GROUP BY c.id, p.id
                    ORDER BY c.id DESC
                    """, (user_id,))
                cart_items = cursor.fetchall()

                # Clean up null image arrays
                for item in cart_items:
                    if item['images'] and item['images'][0] is None:
                        item['images'] = []

        return cors_response(200, {
            "message": "Cart retrieved successfully",
            "cart": cart_items
        })

    except Exception as e:
        print(f"Failed to get cart. Error: {str(e)}")
        return cors_response(500, {"error": f"Error getting cart: {str(e)}"})

########################
def update_cart_item(event, user_id):
    try:
        try:
            body = parse_body(event)
        except ValueError as e:
            return cors_response(400, {'error': str(e)})
        
        post_id = body['postId']
        quantity = body['quantity']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("UPDATE cart SET quantity = %s WHERE userId = %s AND postId = %s RETURNING *",
                            (quantity, user_id, post_id))
                updated_item = cursor.fetchone()
                conn.commit()

        if updated_item:
            return cors_response(200, {
                "message": "Cart item updated successfully",
                "item": updated_item
            })
            
        else:
            return cors_response(404, {"error": "Cart item not found"})

    except Exception as e:
        print(f"Failed to update cart item. Error: {str(e)}")
        return cors_response(500, {"error": f"Error updating cart item: {str(e)}"})

########################
def remove_from_cart(event, user_id):
    try:
        try:
            body = parse_body(event)
        except ValueError as e:
            return cors_response(400, {'error': str(e)})
        
        post_id = body['postId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("DELETE FROM cart WHERE userId = %s AND postId = %s RETURNING *", (user_id, post_id))
                deleted_item = cursor.fetchone()
                conn.commit()

        if deleted_item:
            return cors_response(200, {
                "message": "Item removed from cart successfully",
                "item": deleted_item
            })

        else:
            return cors_response(404, {"error": "Cart item not found"})

    except Exception as e:
        print(f"Failed to remove item from cart. Error: {str(e)}")
        return cors_response(500, {"error": f"Error removing item from cart: {str(e)}"})