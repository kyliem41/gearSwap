import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime
import boto3

def lambda_handler(event, context):
    http_method = event['httpMethod']
    resource_path = event['resource']
    
    try:
        auth_header = event.get('headers', {}).get('Authorization')
        if not auth_header:
            return {
                'statusCode': 401,
                'body': json.dumps({'error': 'No authorization header'})
            }

        # Extract token from Bearer authentication
        token = auth_header.split(' ')[-1]
        verify_token(token)
    except Exception as e:
        return {
            'statusCode': 401,
            'body': json.dumps({'error': f'Authentication failed: {str(e)}'})
        }

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

    return {
        'statusCode': 400,
        'body': json.dumps('Unsupported route')
    }
    
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
    )

########################
def add_to_cart(event, user_id):
    try:
        body = json.loads(event['body'])
        post_id = body['postId']
        quantity = body.get('quantity', 1)

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("SELECT * FROM cart WHERE userId = %s AND postId = %s", (user_id, post_id))
                existing_item = cursor.fetchone()

                if existing_item:
                    cursor.execute("UPDATE cart SET quantity = quantity + %s WHERE userId = %s AND postId = %s RETURNING *",
                                   (quantity, user_id, post_id))
                else:
                    cursor.execute("INSERT INTO cart (userId, postId, quantity) VALUES (%s, %s, %s) RETURNING *",
                                   (user_id, post_id, quantity))

                new_item = cursor.fetchone()
                conn.commit()

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Item added to cart successfully",
                "item": new_item
            })
        }

    except Exception as e:
        print(f"Failed to add item to cart. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error adding item to cart: {str(e)}")
        }

########################
def get_cart(user_id):
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # cursor.execute("""
                #     SELECT c.*, p.title, p.price 
                #     FROM cart c
                #     JOIN posts p ON c.postId = p.id
                #     WHERE c.userId = %s
                # """, (user_id,))
                cursor.execute("""
                               SELECT *
                               FROM cart
                               WHERE userId = %s
                               """, (user_id))
                cart_items = cursor.fetchall()

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Cart retrieved successfully",
                "cart": cart_items
            })
        }

    except Exception as e:
        print(f"Failed to get cart. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error getting cart: {str(e)}")
        }

########################
def update_cart_item(event, user_id):
    try:
        body = json.loads(event['body'])
        post_id = body['postId']
        quantity = body['quantity']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("UPDATE cart SET quantity = %s WHERE userId = %s AND postId = %s RETURNING *",
                               (quantity, user_id, post_id))
                updated_item = cursor.fetchone()
                conn.commit()

        if updated_item:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Cart item updated successfully",
                    "item": updated_item
                })
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("Cart item not found")
            }

    except Exception as e:
        print(f"Failed to update cart item. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error updating cart item: {str(e)}")
        }

########################
def remove_from_cart(event, user_id):
    try:
        body = json.loads(event['body'])
        post_id = body['postId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("DELETE FROM cart WHERE userId = %s AND postId = %s RETURNING *", (user_id, post_id))
                deleted_item = cursor.fetchone()
                conn.commit()

        if deleted_item:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Item removed from cart successfully",
                    "item": deleted_item
                })
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("Cart item not found")
            }

    except Exception as e:
        print(f"Failed to remove item from cart. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error removing item from cart: {str(e)}")
        }