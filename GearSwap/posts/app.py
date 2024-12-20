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
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,Accept',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE',
        'Access-Control-Max-Age': '7200',
        'Content-Type': content_type
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
    elif resource_path == '/posts/{postId}/images':
        if http_method == 'GET':
            return getPostImages(event, context)
        elif http_method == 'POST':
            return addImage(event, context)

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
    
def validate_file_upload(content_type: str, file_data: bytes) -> bool:
    """Validate uploaded file"""
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise ValueError(f"Invalid content type. Allowed types: {ALLOWED_CONTENT_TYPES}")
    
    if len(file_data) > MAX_FILE_SIZE:
        raise ValueError(f"File size exceeds maximum allowed size of {MAX_FILE_SIZE} bytes")
    return True

def store_image(cursor, post_id: int, file_data: bytes, content_type: str) -> int:
    """Store image in the database"""
    # Convert post_id to int if it's a string
    post_id = int(post_id) if isinstance(post_id, str) else post_id

    cursor.execute(
        "INSERT INTO post_images (post_id, image_data, content_type) VALUES (%s, %s, %s) RETURNING id",
        (post_id, base64.b64decode(file_data) if isinstance(file_data, str) else file_data, content_type)  
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
            'data': base64.b64encode(result['image_data']).decode('utf-8'),  # Properly encode binary to base64
            'content_type': result['content_type']
        }
    return None

#############
def createPost(event, context):
    try:
        try:
            body = parse_body(event)
        except ValueError as e:
            return cors_response(400, {'error': str(e)})

        user_id = event['pathParameters']['userId']
        
        VALID_CONDITIONS = {
            'Brand New',
            'Like New',
            'Gently Used',
            'Well Used'
        }
        
        # Validate required fields
        required_fields = ['price', 'description', 'size', 'category', 'condition']
        for field in required_fields:
            if field not in body:
                return cors_response(400, {'error': f"Missing required field: {field}"})
            
        if body['condition'] not in VALID_CONDITIONS:
            return cors_response(400, {
                'error': f"Invalid condition. Must be one of: {', '.join(VALID_CONDITIONS)}"
            })

        # Extract photos array from body
        photos = body.get('photos', [])
        if len(photos) > MAX_IMAGES_PER_POST:
            return cors_response(400, {'error': f"Maximum {MAX_IMAGES_PER_POST} images allowed per post"})

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Check if user exists
                cursor.execute("SELECT username FROM users WHERE id = %s", (user_id,))
                if not cursor.fetchone():
                    return cors_response(404, {'error': "User not found"})

                # Create post
                insert_query = """
                INSERT INTO posts (userId, price, description, size, category, condition, tags, photos) 
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id;
                """
                
                cursor.execute(insert_query, (
                    user_id,
                    Decimal(str(body['price'])),
                    body['description'],
                    body['size'],
                    body['category'],
                    body['condition'],
                    json.dumps(body.get('tags', [])),
                    '[]'
                ))
                post_id = cursor.fetchone()['id']

                # Process uploaded images
                image_ids = []
                for photo in photos:
                    try:
                        # Validate and store each image
                        if 'data' not in photo or 'content_type' not in photo:
                            continue
                            
                        # Remove data:image prefix if present
                        image_data = photo['data']
                        if ';base64,' in image_data:
                            image_data = image_data.split(';base64,')[1]
                            
                        # Decode base64 image data
                        try:
                            decoded_image = base64.b64decode(image_data)
                        except Exception as e:
                            print(f"Failed to decode image: {str(e)}")
                            raise ValueError(f"Invalid base64 image data: {str(e)}")
                            
                        validate_file_upload(photo['content_type'], decoded_image)
                        image_id = store_image(cursor, post_id, decoded_image, photo['content_type'])
                        image_ids.append(image_id)
                    except ValueError as e:
                        return cors_response(400, {'error': str(e)})

                # Update post with image references
                cursor.execute(
                    "UPDATE posts SET photos = %s WHERE id = %s",
                    (json.dumps(image_ids), post_id)
                )

                # Get complete post data
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
                    "post": new_post
                })

    except Exception as e:
        print(f"Failed to create Post. Error: {str(e)}")
        return cors_response(500, {'error': f"Error creating post: {str(e)}"})

################
def getPosts(event, context):
    try:
        query_params = event.get('queryStringParameters') or {}
        page = int(query_params.get('page', 1))
        page_size = int(query_params.get('page_size', 10))
        include_sold = query_params.get('include_sold', 'false').lower() == 'true'
        offset = (page - 1) * page_size

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # First, let's check the structure of the posts table
                cursor.execute("""
                    SELECT column_name, data_type, is_nullable 
                    FROM information_schema.columns 
                    WHERE table_name = 'posts' AND column_name = 'isSold'
                """)
                column_info = cursor.fetchone()
                print(f"isSold column info: {column_info}")
                
                if not include_sold:
                    cursor.execute("SELECT COUNT(*) FROM posts WHERE COALESCE(isSold, false) = FALSE")
                else:
                    cursor.execute("SELECT COUNT(*) FROM posts")
                total_posts = cursor.fetchone()['count']
                
                where_clause = "" if include_sold else "WHERE COALESCE(p.isSold, false) = FALSE"

                query = f"""
                    SELECT 
                        p.id,
                        p.userId,
                        p.price,
                        p.description,
                        p.size,
                        p.category,
                        p.condition,
                        p.tags,
                        COALESCE(p.isSold, false) as "isSold",
                        p.datePosted,
                        p.likeCount,
                        u.username,
                        pi.id as first_image_id,
                        pi.content_type as first_image_content_type,
                        pi.image_data as first_image_data,
                        (
                            SELECT array_agg(
                                json_build_object(
                                    'id', pi2.id,
                                    'content_type', pi2.content_type
                                )
                                ORDER BY pi2.id
                            )
                            FROM post_images pi2
                            WHERE pi2.post_id = p.id
                        ) as photos
                    FROM posts p
                    JOIN users u ON p.userId = u.id
                    LEFT JOIN LATERAL (
                        SELECT id, content_type, image_data
                        FROM post_images
                        WHERE post_id = p.id
                        ORDER BY id
                        LIMIT 1
                    ) pi ON true
                    {where_clause}
                    ORDER BY p.datePosted DESC
                    LIMIT %s OFFSET %s
                """
                
                print(f"Executing query: {query}")
                cursor.execute(query, (page_size, offset))
                posts = cursor.fetchall()

                # Debug each post's isSold status
                for post in posts:
                    raw_is_sold = post.get('issold')  # Note: psycopg2 returns column names in lowercase
                    print(f"Post {post['id']} raw isSold value: {raw_is_sold}, type: {type(raw_is_sold)}")
                    
                    # Convert Decimal to float
                    if 'price' in post:
                        post['price'] = float(post['price'])
                    
                    # Format date
                    if 'datePosted' in post:
                        post['datePosted'] = post['datePosted'].isoformat()

                    # Format first_image
                    if post.get('first_image_id'):
                        post['first_image'] = {
                            'id': post['first_image_id'],
                            'content_type': post['first_image_content_type'],
                            'data': f"data:{post['first_image_content_type']};base64,{base64.b64encode(post['first_image_data']).decode('utf-8')}"
                        }
                    else:
                        post['first_image'] = None

                    # Clean up temporary fields
                    post.pop('first_image_id', None)
                    post.pop('first_image_content_type', None)
                    post.pop('first_image_data', None)

                    # Ensure photos is never null
                    if post['photos'] is None:
                        post['photos'] = []

                formatted_posts = []
                for post in posts:
                    post_copy = dict(post)
                    # Convert isSold to boolean and ensure consistent case
                    post_copy['isSold'] = bool(post_copy.pop('issold', False))
                    formatted_posts.append(post_copy)

                return cors_response(200, {
                    "message": "Posts retrieved successfully",
                    "posts": formatted_posts,
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
        auth_header = event.get('headers', {}).get('Authorization')
        user_id = None
        
        if auth_header:
            token = auth_header.split(' ')[-1]
            payload = verify_token(token)
            user_email = payload.get('email')

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("SELECT id FROM users WHERE email = %s", (user_email,))
                user_result = cursor.fetchone()
                if user_result:
                    user_id = user_result['id']
                        
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                if user_id:
                    cursor.execute("""
                        SELECT p.*, u.username, u.firstname,
                            CASE WHEN lp.id IS NOT NULL THEN true ELSE false END as is_liked
                        FROM posts p
                        JOIN users u ON p.userId = u.id
                        LEFT JOIN likedPost lp ON p.id = lp.postId AND lp.userId = %s
                        WHERE p.id = %s
                    """, (user_id, post_id))
                else:
                    cursor.execute("""
                        SELECT p.*, u.username, u.firstname,
                            false as is_liked
                        FROM posts p
                        JOIN users u ON p.userId = u.id
                        WHERE p.id = %s
                    """, (post_id,))
                
                post = cursor.fetchone()

                if not post:
                    return cors_response(404, {'error': "Post not found"})

                # Get all images for the post
                cursor.execute("""
                    SELECT id, content_type, image_data
                    FROM post_images
                    WHERE post_id = %s
                    ORDER BY created_at
                """, (post_id,))
                raw_images = cursor.fetchall()
                
                # Process images to include proper base64 formatting
                processed_images = []
                for image in raw_images:
                    base64_data = base64.b64encode(image['image_data']).decode('utf-8')
                    processed_images.append({
                        'id': image['id'],
                        'content_type': image['content_type'],
                        'data': f"data:{image['content_type']};base64,{base64_data}"
                    })
                
                # Add processed images to post data
                post['images'] = processed_images

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
        allowed_filters = ['colors', 'condition', 'size', 'category', 'minPrice', 'maxPrice']

        # Build the WHERE clause dynamically
        where_clauses = ["p.userId = %s"]
        params = [user_id]

        for filter_name in allowed_filters:
            if filter_name in query_params:
                if filter_name in ['colors', 'condition', 'size', 'category']:
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
        try:
            body = parse_body(event)
        except ValueError as e:
            return cors_response(400, {'error': str(e)})
        
        user_id = event['pathParameters']['userId']
        post_id = event['pathParameters']['postId']
        
        VALID_CONDITIONS = {
            'Brand New',
            'Like New',
            'Gently Used',
            'Well Used'
        }
        
        print(f"Updating post {post_id} with body: {json.dumps(body)}") 
        
        if 'condition' in body and body['condition'] not in VALID_CONDITIONS:
            return cors_response(400, {
                'error': f"Invalid condition. Must be one of: {', '.join(VALID_CONDITIONS)}"
            })

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Verify post ownership
                cursor.execute("SELECT userId FROM posts WHERE id = %s", (post_id,))
                post = cursor.fetchone()
                if not post or str(post['userid']) != user_id:
                    return cors_response(404, {'error': "Post not found or access denied"})

                update_fields = ['price', 'description', 'size', 'category', 'condition', 'tags', 'issold']
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
                        elif field == 'issold':
                            value = bool(value)
                        update_values.append(value)

                if update_sql:
                    query = f"""
                        UPDATE posts 
                        SET {', '.join(update_sql)}
                        WHERE id = %s AND userId = %s
                        RETURNING *;
                    """
                    update_values.extend([post_id, user_id])
                    print(f"Executing query: {query} with values: {update_values}")
                    cursor.execute(query, update_values)
                    updated_post = cursor.fetchone()
                    print(f"Updated post: {updated_post}")

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
                            
                        elif image['action'] == 'update' and 'id' in image:
                            if 'data' not in image or 'content_type' not in image:
                                continue

                            # Remove data:image prefix if present
                            image_data = image['data']
                            if ';base64,' in image_data:
                                image_data = image_data.split(';base64,')[1]

                            try:
                                # First validate the new image data
                                validate_image(image_data, image['content_type'])

                                # Decode base64 to binary
                                decoded_image = base64.b64decode(image_data)

                                # Then update the existing image
                                cursor.execute(
                                    """
                                    UPDATE post_images 
                                    SET image_data = %s, content_type = %s 
                                    WHERE id = %s AND post_id = %s
                                    """,
                                    (decoded_image, image['content_type'], image['id'], post_id)
                                )
                            except Exception as e:
                                print(f"Error updating image: {str(e)}")
                                continue

                        elif image['action'] == 'delete' and 'id' in image:
                            cursor.execute(
                                "DELETE FROM post_images WHERE id = %s AND post_id = %s",
                                (image['id'], post_id)
                            )

                cursor.execute("""
                    SELECT p.*, u.username,
                        array_agg(
                            CASE WHEN pi.id IS NOT NULL THEN
                                json_build_object(
                                    'id', pi.id,
                                    'content_type', pi.content_type,
                                    'data', concat('data:', pi.content_type, ';base64,', 
                                        replace(encode(pi.image_data, 'base64'), E'\n', ''))
                                )
                            ELSE NULL
                            END
                        ) filter (where pi.id is not null) as images
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
        print("Received event:", json.dumps(event))
        post_id = event['pathParameters']['postId']
        
        try:
            body = parse_body(event)
        except ValueError as e:
            print("Error parsing body:", str(e))
            return cors_response(400, {'error': str(e)})

        if 'data' not in body or 'content_type' not in body:
            return cors_response(400, {'error': 'Missing required fields: data and content_type'})

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                try:
                    # First verify the post exists
                    cursor.execute("SELECT id FROM posts WHERE id = %s", (post_id,))
                    if not cursor.fetchone():
                        return cors_response(404, {'error': 'Post not found'})

                    # Store the image
                    cursor.execute(
                        """
                        INSERT INTO post_images (post_id, image_data, content_type) 
                        VALUES (%s, %s, %s) 
                        RETURNING id, content_type
                        """,
                        (post_id, base64.b64decode(body['data']), body['content_type'])
                    )
                    image_result = cursor.fetchone()
                    
                    # Update the post's photos JSONB array
                    cursor.execute(
                        """
                        UPDATE posts 
                        SET photos = photos || jsonb_build_array(jsonb_build_object(
                            'id', %s,
                            'content_type', %s
                        ))
                        WHERE id = %s
                        """,
                        (image_result['id'], image_result['content_type'], post_id)
                    )
                    
                    conn.commit()
                    
                    return cors_response(201, {
                        'message': 'Image added successfully',
                        'imageId': image_result['id']
                    })
                except Exception as e:
                    print(f"Error processing image: {str(e)}")
                    conn.rollback()
                    return cors_response(500, {'error': f'Error processing image: {str(e)}'})

    except Exception as e:
        print(f"Error in addImage: {str(e)}")
        return cors_response(500, {'error': f'Server error: {str(e)}'})
    
################
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

#################
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

                return cors_response(
                    200, 
                    base64.b64encode(image['image_data']).decode('utf-8'),
                    content_type=image['content_type']
                )

    except Exception as e:
        print(f"Failed to get image: {str(e)}")
        return cors_response(500, {'error': f"Error getting image: {str(e)}"})

#############
def getPostImages(event, context):
    try:
        post_id = event['pathParameters']['postId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get all images for the post
                cursor.execute("""
                    SELECT id, content_type, image_data
                    FROM post_images
                    WHERE post_id = %s
                    ORDER BY id
                """, (post_id,))
                raw_images = cursor.fetchall()
                
                if not raw_images:
                    return cors_response(404, {'error': 'No images found for this post'})

                # Process each image to ensure proper base64 format
                processed_images = []
                for image in raw_images:
                    # Convert binary data to base64 and format properly
                    base64_data = base64.b64encode(image['image_data']).decode('utf-8')
                    processed_images.append({
                        'id': image['id'],
                        'content_type': image['content_type'],
                        'data': f"data:{image['content_type']};base64,{base64_data}"
                    })

                return cors_response(200, {
                    'message': 'Images retrieved successfully',
                    'images': processed_images
                })

    except Exception as e:
        print(f"Failed to get post images: {str(e)}")
        return cors_response(500, {'error': f"Error getting post images: {str(e)}"})