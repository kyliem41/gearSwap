import base64
import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime
from decimal import Decimal
import jwt
import requests
from jwt.algorithms import RSAAlgorithm
import boto3
from typing import Dict, Any

MAX_FILE_SIZE = 5 * 1024 * 1024
MAX_IMAGES_PER_POST = 5
ALLOWED_CONTENT_TYPES = {
    'image/jpeg',
    'image/png'
}

def cors_response(status_code, body, content_type='application/json'):
    """Helper function to create responses with proper CORS headers"""
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

    print(f"HTTP Method: {http_method}")
    print(f"Resource Path: {resource_path}")

    if http_method == 'DELETE' and resource_path == '/posts/delete/{userId}/{postId}':
        return deletePost(event, context)
    elif resource_path == '/posts':
        if http_method == 'GET':
            return getPosts(event, context)
    elif resource_path == '/posts/create/{userId}':
        if http_method == 'POST':
            return createPost(event, context)
    elif resource_path == '/posts/update/{userId}/{postId}':
        return putPost(event, context)
    elif resource_path == '/posts/{postId}':
        return getPostById(event, context)
    elif resource_path == '/posts/{postId}/images/{imageId}':
            if http_method == 'DELETE':
                return deleteImage(event, context)
            elif http_method == 'GET':
                return getImage(event, context)

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

##############
def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""
    if isinstance(obj, datetime):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)  # Convert Decimal to float
    if isinstance(obj, (bytes, bytearray)):  # For JSONB fields
        return json.loads(obj.decode('utf-8'))
    raise TypeError(f"Type {type(obj)} not serializable")

#########
def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT'],
        
        connect_timeout=5
    )

#############
#IMAGES
def validate_image(image_data: str, content_type: str) -> bool:
    """Validate image size and content type"""
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise ValueError(f"Invalid content type. Allowed types: {ALLOWED_CONTENT_TYPES}")
    
    # Decode base64 and check size
    try:
        decoded_data = base64.b64decode(image_data)
        if len(decoded_data) > MAX_FILE_SIZE:
            raise ValueError(f"Image size exceeds maximum allowed size of {MAX_FILE_SIZE} bytes")
        return True
    except Exception as e:
        raise ValueError(f"Invalid image data: {str(e)}")

def store_image(cursor, post_id: int, image_data: str, content_type: str) -> int:
    """Store image in the database and return image ID"""
    decoded_data = base64.b64decode(image_data)
    cursor.execute(
        "INSERT INTO post_images (post_id, image_data, content_type) VALUES (%s, %s, %s) RETURNING id",
        (post_id, decoded_data, content_type)
    )
    return cursor.fetchone()['id']

def get_image(cursor, image_id: int) -> Dict[str, Any]:
    """Retrieve image data from the database"""
    cursor.execute(
        "SELECT image_data, content_type FROM post_images WHERE id = %s",
        (image_id,)
    )
    result = cursor.fetchone()
    if result:
        return {
            'data': base64.b64encode(result['image_data']).decode('utf-8'),
            'content_type': result['content_type']
        }
    return None

#############
def createPost(event, context):
    try:
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = json.loads(event.get('body', '{}'))

        userId = event['pathParameters']['userId']
        price = Decimal(str(body.get('price')))
        description = body.get('description')
        size = body.get('size')
        category = body.get('category')
        clothingType = body.get('clothingType')
        tags = body.get('tags')
        photos = body.get('photos')
        
        required_fields = ['price', 'description', 'size', 'category', 'clothingType']
        for field in required_fields:
            if field not in body:
                return cors_response(400, f"Missing required field: {field}")
            
        images = body.get('images', [])
        if len(images) > MAX_IMAGES_PER_POST:
            return cors_response(400, {'error': f"Maximum {MAX_IMAGES_PER_POST} images allowed per post"})

    except json.JSONDecodeError:
        return cors_response(400, "Invalid JSON format in request body")

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Check if the user exists and get their username
                cursor.execute("SELECT username FROM users WHERE id = %s", (userId,))
                user = cursor.fetchone()
                if not user:
                    return cors_response(404, "User not found")

                insert_query = """
                INSERT INTO posts (userId, price, description, size, category, clothingType, tags, photos) 
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id;
                """
                
                cursor.execute(insert_query, (
                    userId,
                    Decimal(str(body['price'])),
                    body['description'],
                    body['size'],
                    body['category'],
                    body['clothingType'],
                    json.dumps(body.get('tags', [])),
                    '[]'
                ))
                post_id = cursor.fetchone()['id']
                
                image_ids = []
                for image in images:
                    try:
                        validate_image(image['data'], image['content_type'])
                        image_id = store_image(cursor, post_id, image['data'], image['content_type'])
                        image_ids.append(image_id)
                    except ValueError as e:
                        return cors_response(400, {'error': str(e)})

                cursor.execute(
                    "UPDATE posts SET photos = %s WHERE id = %s",
                    (json.dumps(image_ids), post_id)
                )
                
                cursor.execute("""
                    SELECT p.*, u.username, array_agg(pi.id) as image_ids
                    FROM posts p
                    JOIN users u ON p.userId = u.id
                    LEFT JOIN post_images pi ON pi.post_id = p.id
                    WHERE p.id = %s
                    GROUP BY p.id, u.username
                """, (post_id,))
                new_post = cursor.fetchone()

                conn.commit()

        return cors_response(201, {
            "message": "Post created successfully",
            "profile": new_post
        })

    except Exception as e:
        print(f"Failed to create Post. Error: {str(e)}")
        return cors_response(500, f"Error creating post: {str(e)}")

################
def getPosts(event, context):
    try:
        # Get pagination parameters from query string
        query_params = event.get('queryStringParameters') or {}
        page = int(query_params.get('page', 1))
        page_size = int(query_params.get('page_size', 10))        
        offset = (page - 1) * page_size

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get posts with first image for each
                cursor.execute("""
                    SELECT p.*, u.username,
                        (SELECT json_build_object('id', pi.id, 'content_type', pi.content_type)
                        FROM post_images pi
                        WHERE pi.post_id = p.id
                        ORDER BY pi.id
                        LIMIT 1) as first_image
                    FROM posts p
                    JOIN users u ON p.userId = u.id
                    ORDER BY p.datePosted DESC
                    LIMIT %s OFFSET %s
                """, (page_size, offset))
                posts = cursor.fetchall()

                # Get total count
                cursor.execute("SELECT COUNT(*) FROM posts")
                total_posts = cursor.fetchone()['count']

                # Fetch first image data for each post
                for post in posts:
                    if post['first_image']:
                        image_id = post['first_image']['id']
                        image = get_image(cursor, image_id)
                        if image:
                            post['first_image']['data'] = image['data']

                return cors_response(200, {
                    "message": "Posts retrieved successfully",
                    "posts": posts,
                    "page": page,
                    "page_size": page_size,
                    "total_posts": total_posts,
                    "total_pages": -(-total_posts // page_size)
                })

    except Exception as e:
        print(f"Failed to get posts: {str(e)}")
        return cors_response(500, {'error': f"Error getting posts: {str(e)}"})

############
def getPostById(event, context):
    try:
        post_id = event['pathParameters']['postId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("""
                    SELECT p.*, u.username, u.firstname, u.lastname,
                        array_agg(json_build_object('id', pi.id, 'content_type', pi.content_type)) as images
                    FROM posts p
                    JOIN users u ON p.userId = u.id
                    LEFT JOIN post_images pi ON pi.post_id = p.id
                    WHERE p.id = %s
                    GROUP BY p.id, u.username, u.firstname, u.lastname
                """, (post_id,))
                post = cursor.fetchone()

                if not post:
                    return cors_response(404, {'error': "Post not found"})

                # Fetch image data for each image
                if post['images'] and post['images'][0] is not None:
                    for image in post['images']:
                        image_data = get_image(cursor, image['id'])
                        if image_data:
                            image['data'] = image_data['data']

                return cors_response(200, {
                    "message": "Post retrieved successfully",
                    "post": post
                })

    except Exception as e:
        print(f"Error in getPostById: {str(e)}")
        return cors_response(500, {'error': f"Error getting post: {str(e)}"})

############
# GET /posts/filter/{userId}?clothingType=shirt&size=M&minPrice=20&maxPrice=50&page=1&page_size=10
# This would return shirts of size M, priced between $20 and $50, for the specified user, 10 results per page, 
# showing the first page.
def getPostsByFilter(event, context):
    try:
        query_params = event.get('queryStringParameters', {})
        user_id = event['pathParameters']['userId']

        # Define allowed filters
        allowed_filters = ['colors', 'clothingType', 'size', 'category', 'minPrice', 'maxPrice']

        # Build the WHERE clause dynamically
        where_clauses = ["p.userId = %s"]
        params = [user_id]

        for filter_name in allowed_filters:
            if filter_name in query_params:
                if filter_name in ['colors', 'clothingType', 'size', 'category']:
                    where_clauses.append(f"p.{filter_name} = %s")
                    params.append(query_params[filter_name])
                elif filter_name == 'minPrice':
                    where_clauses.append("p.price >= %s")
                    params.append(float(query_params[filter_name]))
                elif filter_name == 'maxPrice':
                    where_clauses.append("p.price <= %s")
                    params.append(float(query_params[filter_name]))

        # Pagination
        page = int(query_params.get('page', 1))
        page_size = int(query_params.get('page_size', 10))
        offset = (page - 1) * page_size

        # Construct the final query with image data
        where_clause = " AND ".join(where_clauses)
        get_query = f"""
            SELECT p.*, u.username,
                (SELECT json_build_object('id', pi.id, 'content_type', pi.content_type)
                    FROM post_images pi
                    WHERE pi.post_id = p.id
                    ORDER BY pi.id
                    LIMIT 1) as first_image
            FROM posts p
            JOIN users u ON p.userId = u.id
            WHERE {where_clause}
            ORDER BY p.datePosted DESC
            LIMIT %s OFFSET %s
        """
        params.extend([page_size, offset])

        count_query = f"SELECT COUNT(*) FROM posts p WHERE {where_clause}"

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(get_query, params)
                posts = cursor.fetchall()

                cursor.execute(count_query, params[:-2])
                total_posts = cursor.fetchone()['count']

                # Fetch first image data for each post
                for post in posts:
                    if post['first_image']:
                        image_id = post['first_image']['id']
                        image = get_image(cursor, image_id)
                        if image:
                            post['first_image']['data'] = image['data']

                return cors_response(200, {
                    "message": "Posts retrieved successfully",
                    "posts": posts,
                    "page": page,
                    "page_size": page_size,
                    "total_posts": total_posts,
                    "total_pages": -(-total_posts // page_size)
                })

    except Exception as e:
        print(f"Failed to get filtered posts: {str(e)}")
        return cors_response(500, {'error': f"Error getting filtered posts: {str(e)}"})

############
def putPost(event, context):
    try:
        body = json.loads(event['body']) if isinstance(event.get('body'), str) else event.get('body', {})
        user_id = event['pathParameters']['userId']
        post_id = event['pathParameters']['postId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Verify post ownership
                cursor.execute("SELECT userId FROM posts WHERE id = %s", (post_id,))
                post = cursor.fetchone()
                if not post or str(post['userId']) != user_id:
                    return cors_response(404, {'error': "Post not found or access denied"})

                # Update post details
                update_fields = ['price', 'description', 'size', 'category', 'clothingType', 'tags']
                update_values = []
                update_sql = []

                for field in update_fields:
                    if field in body:
                        update_sql.append(f"{field} = %s")
                        value = body[field]
                        if field == 'price':
                            value = Decimal(str(value))
                        elif field == 'tags':
                            value = json.dumps(value)
                        update_values.append(value)

                if update_sql:
                    query = f"""
                        UPDATE posts 
                        SET {', '.join(update_sql)}
                        WHERE id = %s AND userId = %s
                        RETURNING *
                    """
                    update_values.extend([post_id, user_id])
                    cursor.execute(query, update_values)
                    updated_post = cursor.fetchone()

                # Handle image updates
                if 'images' in body:
                    images = body['images']
                    for image in images:
                        if 'action' not in image:
                            continue

                        if image['action'] == 'add':
                            if 'data' not in image or 'content_type' not in image:
                                continue
                            validate_image(image['data'], image['content_type'])
                            store_image(cursor, post_id, image['data'], image['content_type'])

                        elif image['action'] == 'delete' and 'id' in image:
                            cursor.execute(
                                "DELETE FROM post_images WHERE id = %s AND post_id = %s",
                                (image['id'], post_id)
                            )

                # Get updated post with images
                cursor.execute("""
                    SELECT p.*, u.username,
                        array_agg(json_build_object('id', pi.id, 'content_type', pi.content_type)) as images
                    FROM posts p
                    JOIN users u ON p.userId = u.id
                    LEFT JOIN post_images pi ON pi.post_id = p.id
                    WHERE p.id = %s
                    GROUP BY p.id, u.username
                """, (post_id,))
                final_post = cursor.fetchone()

                conn.commit()

                return cors_response(200, {
                    "message": "Post updated successfully",
                    "post": final_post
                })

    except Exception as e:
        print(f"Failed to update post: {str(e)}")
        return cors_response(500, {'error': f"Error updating post: {str(e)}"})

############
def deletePost(event, context):
    try:
        user_id = event['pathParameters']['userId']
        post_id = event['pathParameters']['postId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Verify post ownership
                cursor.execute(
                    "SELECT id FROM posts WHERE id = %s AND userId = %s",
                    (post_id, user_id)
                )
                post = cursor.fetchone()
                
                if not post:
                    return cors_response(404, {
                        "error": "Post not found or does not belong to the user"
                    })

                # Delete all images associated with the post
                cursor.execute(
                    "DELETE FROM post_images WHERE post_id = %s",
                    (post_id,)
                )

                # Delete the post
                cursor.execute(
                    "DELETE FROM posts WHERE id = %s AND userId = %s RETURNING id",
                    (post_id, user_id)
                )
                deleted_post = cursor.fetchone()
                conn.commit()

                return cors_response(200, {
                    "message": "Post and associated images deleted successfully",
                    "deletedPostId": deleted_post['id']
                })

    except Exception as e:
        print(f"Failed to delete post: {str(e)}")
        return cors_response(500, {'error': f"Error deleting post: {str(e)}"})
    
###############
# IMAGE FUNCTIONS
def addImage(event, context):
    try:
        user_id = event['pathParameters']['userId']
        post_id = event['pathParameters']['postId']
        
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = json.loads(event.get('body', '{}'))

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Verify post ownership
                cursor.execute(
                    "SELECT userId FROM posts WHERE id = %s",
                    (post_id,)
                )
                post = cursor.fetchone()
                if not post or str(post['userId']) != user_id:
                    return cors_response(404, {'error': "Post not found or access denied"})

                # Check current image count
                cursor.execute(
                    "SELECT COUNT(*) as count FROM post_images WHERE post_id = %s",
                    (post_id,)
                )
                current_count = cursor.fetchone()['count']
                
                if current_count >= MAX_IMAGES_PER_POST:
                    return cors_response(400, {
                        'error': f"Maximum number of images ({MAX_IMAGES_PER_POST}) already reached"
                    })

                # Validate and store new image
                try:
                    validate_image(body['data'], body['content_type'])
                    image_id = store_image(cursor, post_id, body['data'], body['content_type'])
                    
                    # Update post's photos array
                    cursor.execute(
                        "UPDATE posts SET photos = photos || %s WHERE id = %s",
                        (json.dumps([image_id]), post_id)
                    )
                    
                    conn.commit()
                    
                    return cors_response(201, {
                        "message": "Image added successfully",
                        "imageId": image_id
                    })
                except ValueError as e:
                    return cors_response(400, {'error': str(e)})

    except Exception as e:
        print(f"Failed to add image: {str(e)}")
        return cors_response(500, {'error': f"Error adding image: {str(e)}"})
    
def deleteImage(event, context):
    try:
        user_id = event['pathParameters']['userId']
        post_id = event['pathParameters']['postId']
        image_id = event['pathParameters']['imageId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Verify post ownership and image existence
                cursor.execute("""
                    SELECT p.id 
                    FROM posts p
                    JOIN post_images pi ON p.id = pi.post_id
                    WHERE p.id = %s AND p.userId = %s AND pi.id = %s
                """, (post_id, user_id, image_id))
                
                if not cursor.fetchone():
                    return cors_response(404, {
                        "error": "Image not found or access denied"
                    })

                # Get current image count
                cursor.execute(
                    "SELECT COUNT(*) as count FROM post_images WHERE post_id = %s",
                    (post_id,)
                )
                image_count = cursor.fetchone()['count']

                # Delete the image
                cursor.execute(
                    "DELETE FROM post_images WHERE id = %s AND post_id = %s RETURNING id",
                    (image_id, post_id)
                )
                deleted_image = cursor.fetchone()

                # Update the post's photos array
                cursor.execute(
                    "UPDATE posts SET photos = photos - %s WHERE id = %s",
                    (image_id, post_id)
                )

                conn.commit()

                return cors_response(200, {
                    "message": "Image deleted successfully",
                    "deletedImageId": deleted_image['id'],
                    "remainingImages": image_count - 1
                })

    except Exception as e:
        print(f"Failed to delete image: {str(e)}")
        return cors_response(500, {'error': f"Error deleting image: {str(e)}"})

def getImage(event, context):
    try:
        image_id = event['pathParameters']['imageId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(
                    "SELECT image_data, content_type FROM post_images WHERE id = %s",
                    (image_id,)
                )
                image = cursor.fetchone()

                if not image:
                    return cors_response(404, {'error': "Image not found"})

                # Return the image with proper content type
                return {
                    'statusCode': 200,
                    'headers': {
                        'Content-Type': image['content_type'],
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': base64.b64encode(image['image_data']).decode('utf-8'),
                    'isBase64Encoded': True
                }

    except Exception as e:
        print(f"Failed to get image: {str(e)}")
        return cors_response(500, {'error': f"Error getting image: {str(e)}"})
