import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime
from decimal import Decimal
import traceback
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

    if resource_path == '/outfit/{userId}':
        if http_method == 'POST':
            return createOutfit(event, context)
        elif http_method == 'GET':
            return getOutfits(event, context)
    elif resource_path == '/outfit/{userId}/{outfitId}':
        if http_method == 'PUT':
            return putOutfit(event, context)
        elif http_method == 'DELETE':
            return deleteOutfit(event, context)
        elif http_method == 'GET':
            return getOutfitById(event, context)
    elif resource_path == '/outfit/item/{userId}/{outfitId}':
        if http_method == 'POST':
            return addItemByOutfitId(event, context)
        elif http_method == 'DELETE':
            return removeItemByOutfitId(event, context)
        
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

##########
def validate_integer(value, name):
    try:
        return int(value)
    except ValueError:
        raise ValueError(f"{name} must be a valid integer")

##########
def error_response(status_code, message):
    return cors_response(status_code, {"error": message})
    
#########
def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT'],
        
        connect_timeout=5
    )

###########
def createOutfit(event, context):
    try:
        body = json.loads(event['body']) if isinstance(event.get('body'), str) else event.get('body', {})
        
        userId = event['pathParameters'].get('userId')
        
        if not userId:
            return cors_response(400, {"error": "User ID is required"})
        
        name = body.get('name')
        items = body.get('items', [])
        
        if not isinstance(items, list) or not all(isinstance(item, dict) and 'postId' in item and isinstance(item['postId'], int) for item in items):
            return cors_response(400, {"error": "Items must be an array of objects, each containing a postId as an integer"})

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # If no name is provided, generate a default name
                if not name or name.strip() == "":
                    # Query to find the max number used in default names for this user
                    max_number_query = """
                    SELECT MAX(CAST(SUBSTRING(name FROM 'Outfit #(\d+)') AS INTEGER))
                    FROM outfit
                    WHERE userId = %s AND name ~ '^Outfit #\d+$';
                    """
                    cursor.execute(max_number_query, (userId,))
                    max_number = cursor.fetchone()['max']
                    
                    # If no default names exist, start at 1, otherwise increment by 1
                    next_number = 1 if max_number is None else max_number + 1
                    name = f"Outfit #{next_number}"

                insert_query = """
                INSERT INTO outfit (userId, name, items) 
                VALUES (%s, %s, %s::jsonb)
                RETURNING id, userId, name, dateCreated, items;
                """
                
                cursor.execute(insert_query, (userId, name, json.dumps(items)))
                new_outfit = cursor.fetchone()
                conn.commit()

        return cors_response(201, {
            "message": "Outfit created successfully",
            "outfit": new_outfit
        })

    except Exception as e:
        print(f"Failed to create outfit. Error: {str(e)}")
        print("Traceback:")
        traceback.print_exc()
        return cors_response(500, {"error": f"Error creating outfit: {str(e)}"})

################
def getOutfits(event, context):
    try:
        userId = event['pathParameters']['userId']
        
        if not userId:
            return cors_response(400, {"error": "User ID is required"})

        # Get pagination parameters from query string
        query_params = event.get('queryStringParameters') or {}
        page = int(query_params.get('page', 1))
        page_size = int(query_params.get('page_size', 10))
        
        # Calculate offset
        offset = (page - 1) * page_size

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Query to get paginated outfits
                get_query = """
                    SELECT * FROM outfit 
                    WHERE userId = %s 
                    ORDER BY dateCreated DESC 
                    LIMIT %s OFFSET %s
                """
                cursor.execute(get_query, (userId, page_size, offset))
                outfits = cursor.fetchall()

                count_query = "SELECT COUNT(*) FROM outfit WHERE userId = %s"
                cursor.execute(count_query, (userId,))
                total_outfits = cursor.fetchone()['count']

        total_pages = -(-total_outfits // page_size) 

        return cors_response(200, {
            "message": "Outfits retrieved successfully",
            "outfits": outfits,
            "page": page,
            "page_size": page_size,
            "total_outfits": total_outfits,
            "total_pages": total_pages
        })
            
    except Exception as e:
        print(f"Failed to get outfits. Error: {str(e)}")
        return cors_response(500, {"error": f"Error getting outfits: {str(e)}"})
            
############
def putOutfit(event, context):
    try:
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = json.loads(event.get('body', '{}'))

        userId = event['pathParameters']['userId']
        outfitId = event['pathParameters']['outfitId']
        name = body.get('name')
        items = body.get('items')
        
        required_fields = ['name', 'items']
        for field in required_fields:
            if field not in body:
                return cors_response(400, {"error": f"Missing required field: {field}"})
        
        if items and (not isinstance(items, list) or not all(isinstance(item, dict) and 'postId' in item and isinstance(item['postId'], int) for item in items)):
                return cors_response(400, {"error": "Items must be an array of objects, each containing a postId as an integer"})
        
    except json.JSONDecodeError:
        return cors_response(400, {"error": "Invalid JSON format in request body"})

    update_query = """
    UPDATE outfit    
    SET name = COALESCE(%s, name), 
        items = COALESCE(%s::jsonb, items)
    WHERE id = %s AND userId = %s 
    RETURNING id, userId, name, dateCreated, items;
    """

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Convert items to a JSON string
                items_json = json.dumps(items) if items is not None else None
                cursor.execute(update_query, (name, items_json, outfitId, userId))
                updated_outfit = cursor.fetchone()
                conn.commit()
        
        if updated_outfit:
            return cors_response(200, {
                "message": "Outfit updated successfully",
                "outfit": updated_outfit
            })

        else:
            return cors_response(404, {"error": "Outfit not found or does not belong to the user"})
        
    except Exception as e:
        print(f"Failed to update outfit. Error: {str(e)}")
        return cors_response(500, {"error": f"Error updating outfit: {str(e)}"})
        
###########
def deleteOutfit(event, context):
    try:
        userId = validate_integer(event['pathParameters']['userId'], 'User ID')
        outfitId = validate_integer(event['pathParameters']['outfitId'], 'Outfit ID')
    
        if not userId or not outfitId:
            return cors_response(400, {"error": "Missing userId or outfitId in path parameters"})
        
    except KeyError as e:
        return cors_response(400, {"error": f"Missing required parameter: {str(e)}"})
        
    delete_query = "DELETE FROM outfit WHERE Id = %s AND userId = %s RETURNING id;"

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(delete_query, (outfitId, userId))
                deleted_outfit = cursor.fetchone()
                conn.commit()
        
        if deleted_outfit:
            return cors_response(200, {
                "message": "Outfit deleted successfully",
                "removedOutfitId": deleted_outfit['id']
            })

        else:
            return cors_response(404, {"error": "Outfit not found or does not belong to the user"})
        
    except Exception as e:
        print(f"Failed to delete outfit. Error: {str(e)}")
        return cors_response(500, {"error": f"Error deleting outfit: {str(e)}"})
        
    finally:
        if conn:
            conn.close()
            
################
def getOutfitById(event, context):
    try:
        userId = event['pathParameters']['userId']
        outfitId = event['pathParameters']['outfitId']
        
        if not userId or not outfitId:
            return cors_response(400, {"error": "Both User ID and Outfit ID are required"})

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                get_query = """
                    SELECT * FROM outfit 
                    WHERE Id = %s AND userId = %s 
                """
                cursor.execute(get_query, (outfitId, userId))
                outfit = cursor.fetchone()

        if outfit:
            return cors_response(200, {
                "message": "Outfit retrieved successfully",
                "outfit": outfit
            })

        else:
            return cors_response(404, {"error": "Outfit not found"})
            
    except Exception as e:
        print(f"Error in getOutfitById: {str(e)}")
        return cors_response(500, {"error": f"Error retrieving outfit: {str(e)}"})

    finally:
        if conn:
            conn.close()

##########
def addItemByOutfitId(event, context):
    try:
        body = json.loads(event['body']) if isinstance(event.get('body'), str) else event.get('body', {})
        
        userId = event['pathParameters']['userId']
        outfitId = event['pathParameters']['outfitId']
        
        items = body.get('items', [])
        
        if not userId or not outfitId or not items:
            return cors_response(400, {"error": "Missing required parameters"})

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Check if the outfit exists and belongs to the user
                cursor.execute("SELECT * FROM outfit WHERE id = %s AND userId = %s", (outfitId, userId))
                outfit = cursor.fetchone()
                
                if not outfit:
                    return cors_response(404, {"error": "Outfit not found or does not belong to the user"})
                
                existing_items = outfit.get('items', [])
                existing_post_ids = set(item['postId'] for item in existing_items)
                
                for item in items:
                    postId = item.get('postId')
                    if not postId:
                        return cors_response(400, {"error": "Each item must have a postId"})
                    
                    try:
                        postId = int(postId)
                    except ValueError:
                        return cors_response(400, {"error": f"Invalid postId: {postId}. Must be an integer."})
                    
                    if postId in existing_post_ids:
                        return cors_response(400, {"error": f"Item with postId {postId} is already in the outfit"})

                    cursor.execute("SELECT * FROM posts WHERE id = %s", (postId,))
                    post = cursor.fetchone()

                    if not post:
                        return cors_response(404, {"error": f"Post with id {postId} not found"})

                    print(f"Post data: {post}")

                    clothingType = post.get('clothingtype')
                    if not clothingType:
                        return cors_response (400, {"error": f"Post with id {postId} does not have a clothingType"})

                    # Check if an item with the same clothing type already exists in the outfit
                    check_query = """
                    SELECT COUNT(*) as count FROM outfit,
                    jsonb_array_elements(items) as item
                    WHERE id = %s AND (item->>'postId')::int IN (
                        SELECT id FROM posts WHERE clothingtype = %s
                    )
                    """
                    cursor.execute(check_query, (outfitId, clothingType))
                    result = cursor.fetchone()
                    if result and result['count'] > 0:
                        return cors_response(400, {"error": f"An item of type {clothingType} already exists in this outfit"})
                    
                    # Add the new item to the outfit
                    update_query = """
                    UPDATE outfit 
                    SET items = COALESCE(items, '[]'::jsonb) || jsonb_build_array(jsonb_build_object('postId', %s::int))
                    WHERE id = %s AND userId = %s
                    RETURNING id, userId, name, dateCreated, items;
                    """
                    
                    cursor.execute(update_query, (postId, outfitId, userId))
                    updated_outfit = cursor.fetchone()
                    conn.commit()

        return cors_response(200, {
            "message": "Items added to outfit successfully",
            "outfit": updated_outfit
        })

    except Exception as e:
        print(f"Failed to add items to outfit. Error: {str(e)}")
        print("Traceback:")
        traceback.print_exc()
        return cors_response(500, {"error": f"Error adding items to outfit: {str(e)}"})

###########
def removeItemByOutfitId(event, context):
    try:
        body = json.loads(event['body']) if isinstance(event.get('body'), str) else event.get('body', {})
        
        userId = event['pathParameters']['userId']
        outfitId = event['pathParameters']['outfitId']
        
        postId = body.get('postId')
        
        try:
            postId = int(postId)
        except (ValueError, TypeError):
            return cors_response(400, {"error": f"Invalid postId: {postId}. Must be an integer."})
        
        if not userId or not outfitId or postId is None:
            return cors_response(400, {"error": "Missing required parameters"})

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("SELECT * FROM outfit WHERE id = %s AND userId = %s", (outfitId, userId))
                outfit = cursor.fetchone()
                
                if not outfit:
                    return cors_response(404, {"error": "Outfit not found or does not belong to the user"})
                
                update_query = """
                UPDATE outfit 
                SET items = (
                    SELECT jsonb_agg(item)
                    FROM jsonb_array_elements(items) AS item
                    WHERE (item->>'postId')::integer != %s
                )
                WHERE id = %s AND userId = %s
                RETURNING id, userId, name, dateCreated, items;
                """
                
                cursor.execute(update_query, (postId, outfitId, userId))
                updated_outfit = cursor.fetchone()
                conn.commit()

                if updated_outfit['items'] == outfit['items']:
                    return cors_response(404, {"error": "Item not found in the outfit"})

        return cors_response(200, {
            "message": "Item removed from outfit successfully",
            "outfit": updated_outfit
        })

    except Exception as e:
        print(f"Failed to remove item from outfit. Error: {str(e)}")
        return cors_response(500, {"error": f"Error removing item from outfit: {str(e)}"})