import psycopg2
import os
import json
from psycopg2.extras import RealDictCursor
from datetime import datetime
from decimal import Decimal
import traceback
import random

def lambda_handler(event, context):
    try:
        http_method = event['httpMethod']
        resource_path = event['resource']

        if resource_path == '/styler/{userId}':
            if http_method == 'POST':
                return refreshStyler(event, context)
            elif http_method == 'GET':
                return getStyleTips(event, context)
        elif resource_path == '/styler/wardrobe/{userId}':
            if http_method == 'POST':
                return generateOutfitByWardrobe(event, context)
        elif resource_path == '/styler/similar/{postId}':
            if http_method == 'GET':
                return getSimilarItems(event, context)
        elif resource_path == '/styler/trending':
            if http_method == 'GET':
                return getTrendingItems(event, context)
        elif resource_path == '/styler/analysis/{userId}':
            if http_method == 'GET':
                return getStyleAnalysis(event, context)
        elif resource_path == '/styler/outfit/{userId}':
            if http_method == 'POST':
                return generateOutfitRec(event, context)
        elif resource_path == '/styler/item/{userId}':
            if http_method == 'POST':
                return generateItemRec(event, context)
        elif resource_path == '/styler/preferences/{userId}':
            if http_method == 'GET':
                return getStylePreferences(event, context)
            elif http_method == 'PUT':
                return putStylePreferences(event, context)

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
def putStylePreferences(event, context):
    try:
        userId = event['pathParameters']['userId']
        body = json.loads(event['body'])
        preferences = body.get('preferences', [])

        if not preferences:
            return error_response(400, "Preferences are required")

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Check if a row for this user already exists
                check_query = "SELECT id FROM aiStyler WHERE userId = %s"
                cursor.execute(check_query, (userId,))
                existing_row = cursor.fetchone()

                if existing_row:
                    # Update existing row
                    update_query = """
                    UPDATE aiStyler
                    SET preferences = %s::jsonb
                    WHERE userId = %s
                    RETURNING id, userId, preferences;
                    """
                    cursor.execute(update_query, (json.dumps(preferences), userId))
                else:
                    # Insert new row
                    insert_query = """
                    INSERT INTO aiStyler (userId, preferences)
                    VALUES (%s, %s::jsonb)
                    RETURNING id, userId, preferences;
                    """
                    cursor.execute(insert_query, (userId, json.dumps(preferences)))

                updated_preferences = cursor.fetchone()
                conn.commit()

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Style preferences updated successfully",
                "preferences": updated_preferences
            }, default=json_serial)
        }

    except Exception as e:
        print(f"Error in putStylePreferences: {str(e)}")
        return error_response(500, f"Error updating style preferences: {str(e)}")

##############
def getStylePreferences(event, context):
    try:
        userId = event['pathParameters']['userId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                get_query = """
                SELECT id, userId, preferences
                FROM aiStyler
                WHERE userId = %s;
                """
                cursor.execute(get_query, (userId,))
                preferences = cursor.fetchone()

        if preferences:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Style preferences retrieved successfully",
                    "preferences": preferences
                }, default=json_serial)
            }
        else:
            return error_response(404, "Style preferences not found for this user")

    except Exception as e:
        print(f"Error in getStylePreferences: {str(e)}")
        return error_response(500, f"Error retrieving style preferences: {str(e)}")

############
def generateOutfitRec(event, context):
    try:        
        userId = event['pathParameters'].get('userId')
        if not userId:
            return error_response(400, "userId is required in path parameters")
        
        body = event.get('body', '{}')
        if isinstance(body, str):
            body = json.loads(body)
        elif body is None:
            body = {}
        
        occasion = body.get('occasion')
        season = body.get('season')

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get user preferences
                cursor.execute("SELECT preferences FROM aiStyler WHERE userId = %s", (userId,))
                user_preferences_row = cursor.fetchone()

                if not user_preferences_row:
                    return error_response(404, "User preferences not found")

                user_preferences = user_preferences_row.get('preferences', {})

                # Get user's wardrobe (liked posts)
                cursor.execute("""
                    SELECT p.* FROM posts p
                    JOIN likedPost lp ON p.id = lp.postId
                    WHERE lp.userId = %s
                """, (userId,))
                wardrobe = cursor.fetchall()

                if not wardrobe:
                    return error_response(404, "User has no liked posts to generate outfit from")

                # Here you would implement your outfit generation logic
                # For this example, we'll just return a random selection of items
                outfit = random.sample(wardrobe, min(2, len(wardrobe)))

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Outfit recommendation generated",
                "outfit": outfit
            }, default=json_serial)
        }

    except Exception as e:
        return error_response(500, f"Error generating outfit recommendation: {str(e)}")
    
############
def generateItemRec(event, context):
    try:        
        userId = event['pathParameters'].get('userId')
        if not userId:
            return error_response(400, "userId is required in path parameters")
        
        body = event.get('body', '{}')
        if isinstance(body, str):
            body = json.loads(body)
        elif body is None:
            body = {}
        
        category = body.get('category')
        if not category:
            return error_response(400, "category is required in request body")

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get user preferences
                cursor.execute("SELECT preferences FROM aiStyler WHERE userId = %s", (userId,))
                user_preferences_row = cursor.fetchone()

                if not user_preferences_row:
                    return error_response(404, "User preferences not found")

                user_preferences = user_preferences_row.get('preferences', {})

                # Get recommended items based on user preferences and category
                query = """
                SELECT * FROM posts
                WHERE category = %s
                AND userId != %s
                ORDER BY likeCount DESC
                LIMIT 10;
                """
                cursor.execute(query, (category, userId))
                recommended_items = cursor.fetchall()

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Item recommendations generated",
                "items": recommended_items
            }, default=json_serial)
        }

    except Exception as e:
        return error_response(500, f"Error generating item recommendations: {str(e)}")

############
def getStyleAnalysis(event, context):
    try:
        userId = event['pathParameters']['userId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get user's posts
                cursor.execute("SELECT * FROM posts WHERE userId = %s", (userId,))
                user_posts = cursor.fetchall()

                # Get user's liked posts
                cursor.execute("""
                    SELECT p.* FROM posts p
                    JOIN likedPost lp ON p.id = lp.postId
                    WHERE lp.userId = %s
                """, (userId,))
                liked_posts = cursor.fetchall()

                # Perform analysis (this is a placeholder - implement your own analysis logic)
                analysis = {
                    "total_items": len(user_posts),
                    "favorite_category": max(set(post['category'] for post in user_posts), key=lambda x: sum(post['category'] == x for post in user_posts)),
                    "liked_categories": list(set(post['category'] for post in liked_posts)),
                    # Add more analysis as needed
                }

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Style analysis generated",
                "analysis": analysis
            }, default=json_serial)
        }

    except Exception as e:
        print(f"Error in getStyleAnalysis: {str(e)}")
        return error_response(500, f"Error generating style analysis: {str(e)}")

############
def getTrendingItems(event, context):
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                query = """
                SELECT * FROM posts
                ORDER BY likeCount DESC
                LIMIT 20;
                """
                cursor.execute(query)
                trending_items = cursor.fetchall()

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Trending items retrieved",
                "items": trending_items
            }, default=json_serial)
        }

    except Exception as e:
        print(f"Error in getTrendingItems: {str(e)}")
        return error_response(500, f"Error retrieving trending items: {str(e)}")

############
def getSimilarItems(event, context):
    try:
        postId = event['pathParameters']['postId']

        if not postId:
            return error_response(400, "postId is required")

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get the original post
                cursor.execute("SELECT * FROM posts WHERE id = %s", (postId,))
                original_post = cursor.fetchone()

                if not original_post:
                    return error_response(404, "Original post not found")

                # Get similar items based on tags and category
                query = """
                SELECT * FROM posts
                WHERE id != %s
                AND category = %s
                AND tags ?| %s
                ORDER BY likeCount DESC
                LIMIT 10;
                """
                cursor.execute(query, (postId, original_post['category'], original_post['tags']))
                similar_items = cursor.fetchall()

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Similar items retrieved",
                "items": similar_items
            }, default=json_serial)
        }

    except Exception as e:
        print(f"Error in getSimilarItems: {str(e)}")
        return error_response(500, f"Error retrieving similar items: {str(e)}")

###########
def generateOutfitByWardrobe(event, context):
    try:        
        userId = event['pathParameters'].get('userId')
        if not userId:
            return error_response(400, "userId is required in path parameters")
        
        body = event.get('body', '{}')
        if body is not None:
            if isinstance(body, str):
                body = json.loads(body)
        else:
            body = {}
        
        occasion = body.get('occasion')
        season = body.get('season')

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get user's wardrobe (liked posts)
                cursor.execute("""
                    SELECT p.* FROM posts p
                    JOIN likedPost lp ON p.id = lp.postId
                    WHERE lp.userId = %s
                """, (userId,))
                wardrobe = cursor.fetchall()

                if not wardrobe:
                    return error_response(404, "User has no liked posts to generate outfit from")

                # Here you would implement your outfit generation logic
                # For this example, we'll just return a random selection of items
                outfit = random.sample(wardrobe, min(2, len(wardrobe)))

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Outfit generated from wardrobe",
                "outfit": outfit
            }, default=json_serial)
        }

    except json.JSONDecodeError as e:
        return error_response(400, f"Invalid JSON in request body: {str(e)}")
    except Exception as e:
        return error_response(500, f"Error generating outfit from wardrobe: {str(e)}")

##############
def getStyleTips(event, context):
    try:
        userId = event['pathParameters']['userId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get user preferences
                cursor.execute("SELECT preferences FROM aiStyler WHERE userId = %s", (userId,))
                user_preferences = cursor.fetchone()

                if not user_preferences:
                    return error_response(404, "User preferences not found")

                # Generate style tips based on user preferences
                # This is a placeholder - implement your own logic for generating tips
                tips = [
                    "Mix and match patterns for a bold look",
                    "Incorporate more color into your wardrobe",
                    "Experiment with layering different textures",
                    "Try accessorizing with statement pieces",
                    "Invest in versatile, classic pieces"
                ]

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Style tips retrieved",
                "tips": tips
            }, default=json_serial)
        }

    except Exception as e:
        print(f"Error in getStyleTips: {str(e)}")
        return error_response(500, f"Error retrieving style tips: {str(e)}")

###########
def refreshStyler(event, context):
    try:
        userId = event['pathParameters']['userId']

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get user's posts, liked posts, and saved posts
                cursor.execute("SELECT * FROM posts WHERE userId = %s", (userId,))
                user_posts = cursor.fetchall()

                cursor.execute("""
                    SELECT p.* FROM posts p
                    JOIN likedPost lp ON p.id = lp.postId
                    WHERE lp.userId = %s
                """, (userId,))
                liked_posts = cursor.fetchall()

                # Analyze user's style and update preferences
                # This is a placeholder - implement your own analysis and update logic
                new_preferences = {
                    "favorite_categories": list(set(post['category'] for post in user_posts)),
                    "liked_categories": list(set(post['category'] for post in liked_posts)),
                    # Add more preference data as needed
                }

                # Update aiStyler table
                update_query = """
                UPDATE aiStyler
                SET preferences = %s::jsonb
                WHERE userId = %s
                RETURNING id, userId, preferences;
                """
                cursor.execute(update_query, (json.dumps(new_preferences), userId))
                updated_styler = cursor.fetchone()
                conn.commit()

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Styler refreshed successfully",
                "updatedStyler": updated_styler
            }, default=json_serial)
        }

    except Exception as e:
        print(f"Error in refreshStyler: {str(e)}")
        return error_response(500, f"Error refreshing styler: {str(e)}")