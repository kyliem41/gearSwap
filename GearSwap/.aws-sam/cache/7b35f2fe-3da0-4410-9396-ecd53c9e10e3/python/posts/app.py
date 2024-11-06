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

def cors_response(status_code, body):
    """Helper function to create responses with proper CORS headers"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',  # Configure this to match your domain in production
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE'
        },
        'body': json.dumps(body, default=str)
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
                RETURNING id, userId, price, description, size, category, clothingType, tags, photos;
                """
                
                # Convert tags and photos to JSON strings
                tags_json = json.dumps(tags)
                photos_json = json.dumps(photos)
                
                cursor.execute(insert_query, (userId, price, description, size, category, clothingType, tags_json, photos_json))
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
        
        # Calculate offset
        offset = (page - 1) * page_size

        get_query = """
        SELECT *
        FROM posts
        ORDER BY id
        LIMIT %s OFFSET %s
        """
        
        count_query = "SELECT COUNT(*) FROM posts"
        
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(get_query, (page_size, offset))
                posts = cursor.fetchall()
                
                cursor.execute(count_query)
                total_posts = cursor.fetchone()['count']

        total_pages = -(-total_posts // page_size)  # Ceiling division

        if posts:
            return cors_response(200, {
                "message": "Posts retrieved successfully",
                "posts": posts,
                "page": page,
                "page_size": page_size,
                "total_posts": total_posts,
                "total_pages": total_pages
            })

        else:
            return cors_response(404, "No posts found for this page")
            
    except Exception as e:
        print(f"Failed to get posts. Error: {str(e)}")
        return cors_response(500, f"Error getting posts: {str(e)}")

############
def getPostById(event, context):
    try:
        postId = event['pathParameters']['postId']
        
        get_post_query = """
            SELECT p.*, u.username, u.firstname, u.lastname 
            FROM posts p
            JOIN users u ON p.userid = u.id
            WHERE p.id = %s
            """
        
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(get_post_query, (postId))
                post = cursor.fetchone()

                if post:
                    return cors_response(200, {
                        "message": "Post retrieved successfully",
                        "post": post
                    })
                    
                else:
                    return cors_response(404, "Post not found")
                
    except Exception as e:
        print(f"Error in getPostById: {str(e)}")
        return cors_response(500, f"Error getting post: {str(e)}")

    finally:
        if conn:
            conn.close()

############
# GET /posts/filter/{userId}?clothingType=shirt&size=M&minPrice=20&maxPrice=50&page=1&page_size=10
# This would return shirts of size M, priced between $20 and $50, for the specified user, 10 results per page, 
# showing the first page.
def getPostsByFilter(event, context):
    try:
        # Get filter parameters from query string
        query_params = event.get('queryStringParameters', {})
        userId = event['pathParameters']['userId']

        # Define allowed filters
        allowed_filters = ['colors', 'clothingType', 'size', 'category', 'minPrice', 'maxPrice']

        # Build the WHERE clause dynamically
        where_clauses = ["userId = %s"]
        params = [userId]

        for filter_name in allowed_filters:
            if filter_name in query_params:
                if filter_name in ['colors', 'clothingType', 'size', 'category']:
                    where_clauses.append(f"{filter_name} = %s")
                    params.append(query_params[filter_name])
                elif filter_name == 'minPrice':
                    where_clauses.append("price >= %s")
                    params.append(float(query_params[filter_name]))
                elif filter_name == 'maxPrice':
                    where_clauses.append("price <= %s")
                    params.append(float(query_params[filter_name]))

        # Pagination
        page = int(query_params.get('page', 1))
        page_size = int(query_params.get('page_size', 10))
        offset = (page - 1) * page_size

        # Construct the final query
        where_clause = " AND ".join(where_clauses)
        get_query = f"""
        SELECT *
        FROM posts
        WHERE {where_clause}
        ORDER BY id
        LIMIT %s OFFSET %s
        """
        params.extend([page_size, offset])

        count_query = f"SELECT COUNT(*) FROM posts WHERE {where_clause}"

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(get_query, params)
                posts = cursor.fetchall()

                cursor.execute(count_query, params[:-2])
                total_posts = cursor.fetchone()['count']

        total_pages = -(-total_posts // page_size)

        if posts:
            return cors_response(200, {
                "message": "Posts retrieved successfully",
                "posts": posts,
                "page": page,
                "page_size": page_size,
                "total_posts": total_posts,
                "total_pages": total_pages
            })

        else:
            return cors_response(404, "No posts found matching the filters")

    except Exception as e:
        print(f"Failed to get filtered posts. Error: {str(e)}")
        return cors_response(500, f"Error getting filtered posts: {str(e)}")

############
def putPost(event, context):
    try:
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = json.loads(event.get('body', '{}'))

        userId = event['pathParameters']['userId'] #Id
        postId = event['pathParameters']['postId']
        price = Decimal(str(body.get('price')))
        description = body.get('description')
        size = body.get('size')
        category = body.get('category')
        clothingType = body.get('clothingType')
        tags = body.get('tags')
        photos = body.get('photos')
        
    except json.JSONDecodeError:
        return cors_response(400, "Invalid JSON format in request body")

    update_query = """
        UPDATE posts    
        SET price = COALESCE(%s, price), 
            description = COALESCE(%s, description), 
            size = COALESCE(%s, size),
            category = COALESCE(%s, category),
            clothingType = COALESCE(%s, clothingType),
            tags = COALESCE(%s, tags),
            photos = COALESCE(%s, photos)
        WHERE id = %s AND userId = %s 
        RETURNING id, userId, price, description, size, category, clothingType, tags, photos, likeCount;
        """
    tags_json = json.dumps(tags)
    photos_json = json.dumps(photos)
    
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(update_query, (price, description, size, category, clothingType, tags_json, photos_json, postId, userId))
                updated_post = cursor.fetchone()
                
                if updated_post:
                    cursor.execute("SELECT username FROM users WHERE id = %s", (userId,))
                    user = cursor.fetchone()
                    if user:
                        updated_post['username'] = user['username']
                
                conn.commit()
        
        if updated_post:
            return cors_response(200, {
                "message": "Post updated successfully",
                "post": updated_post
            })

        else:
            return cors_response(404, "Post not found or does not belong to the user")
        
    except Exception as e:
        print(f"Failed to update post. Error: {str(e)}")
        return cors_response(500, f"Error updating post: {str(e)}")

############
def deletePost(event, context):
    try:
        userId = event['pathParameters']['userId']
        postId = event['pathParameters']['postId']
        
        if not postId:
            return cors_response(400, "Missing postId in path parameters")
        
    except KeyError as e:
        return cors_response(400, f"Missing required parameter: {str(e)}")
        
    delete_query = "DELETE FROM posts WHERE id = %s AND userId = %s RETURNING id;"

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(delete_query, (postId, userId))
                deleted_post = cursor.fetchone()
                conn.commit()
        
        if deleted_post:
            return cors_response(200, {
                "message": "Post deleted successfully",
                "deletedPostId": deleted_post['id']
            })
            
        else:
            return cors_response(404, "Post not found or does not belong to the user")
        
    except Exception as e:
        print(f"Failed to delete post. Error: {str(e)}")
        return cors_response(500, f"Error deleting post: {str(e)}")
    
    finally:
        if conn:
            conn.close()