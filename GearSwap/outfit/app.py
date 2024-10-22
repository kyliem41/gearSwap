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

def lambda_handler(event, context):
    try:
        http_method = event['httpMethod']
        resource_path = event['resource']

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

        return {
            'statusCode': 400,
            'body': json.dumps('Unsupported route')
        }
    except Exception as e:
        print(f"Unexpected error in lambda_handler: {str(e)}")
        print("Traceback:")
        traceback.print_exc()
        return error_response(500, f"Unexpected error: {str(e)}")

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
    return {
        "statusCode": status_code,
        "body": json.dumps({"error": message})
    }
    
#########
def get_db_connection():
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        port=os.environ['DB_PORT'],
    )

###########
def createOutfit(event, context):
    try:
        body = json.loads(event['body']) if isinstance(event.get('body'), str) else event.get('body', {})
        
        userId = event['pathParameters'].get('userId')
        
        if not userId:
            return error_response(400, "User ID is required")
        
        name = body.get('name')
        items = body.get('items', [])
        
        if not isinstance(items, list) or not all(isinstance(item, dict) and 'postId' in item and isinstance(item['postId'], int) for item in items):
            return error_response(400, "Items must be an array of objects, each containing a postId as an integer")

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

        return {
            "statusCode": 201,
            "body": json.dumps({
                "message": "Outfit created successfully",
                "outfit": new_outfit
            }, default=json_serial)
        }

    except Exception as e:
        print(f"Failed to create outfit. Error: {str(e)}")
        print("Traceback:")
        traceback.print_exc()
        return error_response(500, f"Error creating outfit: {str(e)}")

################
def getOutfits(event, context):
    try:
        userId = event['pathParameters']['userId']
        
        if not userId:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "User ID is required"})
            }

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

                # Query to get total count of outfits
                count_query = "SELECT COUNT(*) FROM outfit WHERE userId = %s"
                cursor.execute(count_query, (userId,))
                total_outfits = cursor.fetchone()['count']

        total_pages = -(-total_outfits // page_size)  # Ceiling division

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Outfits retrieved successfully",
                "outfits": outfits,
                "page": page,
                "page_size": page_size,
                "total_outfits": total_outfits,
                "total_pages": total_pages
            }, default=json_serial)
        }
            
    except Exception as e:
        print(f"Failed to get outfits. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Error getting outfits: {str(e)}"})
        }
            
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
                return {
            "statusCode": 400,
            "body": json.dumps(f"Missing required field: {field}")
            }
        
        if items and (not isinstance(items, list) or not all(isinstance(item, dict) and 'postId' in item and isinstance(item['postId'], int) for item in items)):
                return {
                    "statusCode": 400,
                    "body": json.dumps("Items must be an array of objects, each containing a postId as an integer")
                }
        
    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "body": json.dumps("Invalid JSON format in request body")
        }

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
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Outfit updated successfully",
                    "outfit": updated_outfit
                }, default=json_serial)
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("Outfit not found or does not belong to the user")
            }
        
    except Exception as e:
        print(f"Failed to update outfit. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error updating outfit: {str(e)}")
        }
        
###########
def deleteOutfit(event, context):
    try:
        userId = validate_integer(event['pathParameters']['userId'], 'User ID')
        outfitId = validate_integer(event['pathParameters']['outfitId'], 'Outfit ID')
    
        if not userId or not outfitId:
            return error_response(400, "Missing userId or outfitId in path parameters")
        
    except KeyError as e:
        return {
            "statusCode": 400,
            "body": json.dumps(f"Missing required parameter: {str(e)}")
        }
        
    delete_query = "DELETE FROM outfit WHERE Id = %s AND userId = %s RETURNING id;"

    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(delete_query, (outfitId, userId))
                deleted_outfit = cursor.fetchone()
                conn.commit()
        
        if deleted_outfit:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Outfit deleted successfully",
                    "removedOutfitId": deleted_outfit['id']
                })
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps("Outfit not found or does not belong to the user")
            }
        
    except Exception as e:
        print(f"Failed to delete outfit. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error deleting outfit: {str(e)}")
        }
        
    finally:
        if conn:
            conn.close()
            
################
def getOutfitById(event, context):
    try:
        userId = event['pathParameters']['userId']
        outfitId = event['pathParameters']['outfitId']
        
        if not userId or not outfitId:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Both User ID and Outfit ID are required"})
            }

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                get_query = """
                    SELECT * FROM outfit 
                    WHERE Id = %s AND userId = %s 
                """
                cursor.execute(get_query, (outfitId, userId))
                outfit = cursor.fetchone()

        if outfit:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Outfit retrieved successfully",
                    "outfit": outfit
                }, default=json_serial)
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps({"message": "Outfit not found"})
            }
            
    except Exception as e:
        print(f"Error in getOutfitById: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "An error occurred while retrieving the outfit."})
        }
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
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing required parameters"})
            }

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Check if the outfit exists and belongs to the user
                cursor.execute("SELECT * FROM outfit WHERE id = %s AND userId = %s", (outfitId, userId))
                outfit = cursor.fetchone()
                
                if not outfit:
                    return {
                        "statusCode": 404,
                        "body": json.dumps({"error": "Outfit not found or does not belong to the user"})
                    }
                
                existing_items = outfit.get('items', [])
                existing_post_ids = set(item['postId'] for item in existing_items)
                
                for item in items:
                    postId = item.get('postId')
                    if not postId:
                        return {
                            "statusCode": 400,
                            "body": json.dumps({"error": "Each item must have a postId"})
                        }
                    
                    # Ensure postId is an integer
                    try:
                        postId = int(postId)
                    except ValueError:
                        return {
                            "statusCode": 400,
                            "body": json.dumps({"error": f"Invalid postId: {postId}. Must be an integer."})
                        }
                    
                    if postId in existing_post_ids:
                        return {
                            "statusCode": 400,
                            "body": json.dumps({"error": f"Item with postId {postId} is already in the outfit"})
                        }

                    # Get the clothing type of the post
                    cursor.execute("SELECT * FROM posts WHERE id = %s", (postId,))
                    post = cursor.fetchone()

                    if not post:
                        return {
                            "statusCode": 404,
                            "body": json.dumps({"error": f"Post with id {postId} not found"})
                        }

                    print(f"Post data: {post}")  # Debug print

                    clothingType = post.get('clothingtype')
                    if not clothingType:
                        return {
                            "statusCode": 400,
                            "body": json.dumps({
                                "error": f"Post with id {postId} does not have a clothingType",
                                "post_data": post
                            })
                        }

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
                        return {
                            "statusCode": 400,
                            "body": json.dumps({"error": f"An item of type {clothingType} already exists in this outfit"})
                        }
                    
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

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Items added to outfit successfully",
                "outfit": updated_outfit
            }, default=json_serial)
        }

    except Exception as e:
        print(f"Failed to add items to outfit. Error: {str(e)}")
        print("Traceback:")
        traceback.print_exc()
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Error adding items to outfit: {str(e)}"})
        }

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
            return {
                "statusCode": 400,
                "body": json.dumps({"error": f"Invalid postId: {postId}. Must be an integer."})
            }
        
        if not userId or not outfitId or postId is None:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing required parameters"})
            }

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("SELECT * FROM outfit WHERE id = %s AND userId = %s", (outfitId, userId))
                outfit = cursor.fetchone()
                
                if not outfit:
                    return {
                        "statusCode": 404,
                        "body": json.dumps({"error": "Outfit not found or does not belong to the user"})
                    }
                
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
                    return {
                        "statusCode": 404,
                        "body": json.dumps({"error": "Item not found in the outfit"})
                    }

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Item removed from outfit successfully",
                "outfit": updated_outfit
            }, default=json_serial)
        }

    except Exception as e:
        print(f"Failed to remove item from outfit. Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Error removing item from outfit: {str(e)}"})
        }