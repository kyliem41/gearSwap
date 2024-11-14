import os
import json
from typing import Dict, Any
import psycopg2
from psycopg2.extras import RealDictCursor
import asyncio
from datetime import datetime
import jwt
import requests
from jwt.algorithms import RSAAlgorithm
import boto3
from ably import AblyRest
import traceback
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config_manager import config_manager
from styler import FashionGPTRecommender

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

def get_or_create_eventloop():
    try:
        return asyncio.get_event_loop()
    except RuntimeError as ex:
        if "There is no current event loop in thread" in str(ex):
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            return asyncio.get_event_loop()
        raise
    
def lambda_handler(event, context):
    if event['httpMethod'] == 'OPTIONS':
        return cors_response(200, {'message': 'OK'})
    
    loop = get_or_create_eventloop()
    return loop.run_until_complete(_handle_request(event, context))

def initialize_ably_client(api_key):
    """Initialize Ably REST client"""
    try:
        print("Initializing Ably client")
        rest_client = AblyRest(key=api_key)
        test_channel = rest_client.channels.get('test')
        test_channel.publish('test', {'test': 'connection'})
        print("Successfully initialized Ably client")
        return rest_client
    except Exception as e:
        print(f"Error initializing Ably client: {str(e)}")
        traceback.print_exc()
        raise

async def _handle_request(event, context):
    conn = None
    ably_client = None
    
    try:
        auth_header = event.get('headers', {}).get('Authorization')
        if not auth_header:
            return cors_response(401, {'error': 'No authorization header'})

        token = auth_header.split(' ')[-1]
        verify_token(token)
        
        conn = get_db_connection()
        ably_api_key = config_manager.get_secret('ABLY_API_KEY')
        ably_client = initialize_ably_client(ably_api_key)
        
        print("Initialized all connections successfully")
        
        recommender = FashionGPTRecommender(conn)

        resource_path = event['resource']
        http_method = event['httpMethod']

        if resource_path == '/styler/chat/{userId}' and http_method == 'POST':
            return await handle_chat(event, context, conn, ably_client, recommender)
        elif resource_path == '/styler/chat/{userId}/history':
            return get_chat_history(event, context)
        elif resource_path == '/styler/{userId}':
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
        

        return cors_response(404, {'error': 'Route not found'})

    except Exception as e:
        print(f"Request handling error: {str(e)}")
        traceback.print_exc()
        return cors_response(500, {'error': str(e)})
    
    finally:
        if conn:
            conn.close()
            
##################
#CHAT
async def handle_chat(event, context, conn, ably_client, recommender):
    try:
        userId = event['pathParameters']['userId']
        body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']

        if not body.get('message'):
            return cors_response(400, {'error': 'Message content is required'})

        print(f"Processing chat request for user {userId}")

        response = await recommender.get_recommendation(
            user_id=userId,
            request_type=body.get('type', 'conversation'),
            message=body.get('message'),
            context=body.get('context', [])
        )
        print(f"Got AI response for user {userId}")

        # Get the AI's response text and metadata
        ai_response = response['recommendation']
        model_used = response.get('context', {}).get('model_used', 'unknown')
        timestamp = datetime.now().isoformat()

        # Prepare message data
        message_data = {
            'response': ai_response,
            'type': 'ai',
            'model': model_used,
            'timestamp': timestamp
        }

        # Publish to Ably channel
        try:
            channel_name = f"stylist:{userId}"
            channel = ably_client.channels.get(channel_name)
            print(f"Publishing to Ably channel {channel_name}")

            # Use the async publish method
            await channel.publish('stylist_response', message_data)
            print(f"Successfully published to Ably channel {channel_name}")

        except Exception as ably_error:
            print(f"Error publishing to Ably: {str(ably_error)}")
            print(f"Ably error details: {traceback.format_exc()}")

        # Log the conversation
        insert_chat_log(
            conn=conn,
            user_id=userId,
            user_message=body.get('message'),
            ai_response=ai_response,
            request_type=body.get('type', 'conversation'),
            timestamp=timestamp,
            model_used=model_used
        )

        return cors_response(200, {
            'message': 'Message processed successfully',
            'response': ai_response,
            'model_used': model_used,
            'channel': channel_name,
            'timestamp': timestamp
        })

    except Exception as e:
        print(f"Chat handler error: {str(e)}")
        traceback.print_exc()
        return cors_response(500, {'error': str(e)})
                
def insert_chat_log(conn, user_id, user_message, ai_response, request_type, timestamp, model_used):
    with conn.cursor() as cursor:
        cursor.execute("""
            INSERT INTO conversation_logs 
            (user_id, user_message, ai_response, request_type, timestamp, model_used)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id;
        """, (
            user_id,
            user_message,
            ai_response,
            request_type,
            timestamp,
            model_used
        ))
        log_id = cursor.fetchone()[0]
        conn.commit()
        print(f"Logged conversation with ID: {log_id}")
        return log_id
    
#########
def get_chat_history(event, context):
    try:
        userId = event['pathParameters']['userId']
        print(f"Fetching chat history for userId: {userId}")

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                history_query = """
                SELECT id, user_message, ai_response, request_type, timestamp, model_used
                FROM conversation_logs 
                WHERE user_id = %s
                ORDER BY timestamp ASC
                """
                cursor.execute(history_query, (userId,))
                history = cursor.fetchall()
                print(f"Chat history fetched: {history}")

                formatted_history = []
                for entry in history:
                    # Add user message
                    formatted_history.append({
                        'message': entry['user_message'],
                        'timestamp': entry['timestamp'],
                        'type': 'user'
                    })
                    # Add AI response
                    formatted_history.append({
                        'message': entry['ai_response'],
                        'timestamp': entry['timestamp'],
                        'type': 'ai',
                        'model': entry['model_used'],
                        'request_type': entry['request_type']
                    })

        return cors_response(200, {
            "message": "Chat history retrieved successfully",
            "history": formatted_history
        })

    except Exception as e:
        print(f"Error retrieving chat history: {str(e)}")
        print(traceback.format_exc())
        return cors_response(500, {"error": f"Error retrieving chat history: {str(e)}"})

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
    try:
        return psycopg2.connect(
            host=os.environ['DB_HOST'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            port=os.environ['DB_PORT'],
            connect_timeout=5
        )
    except Exception as e:
        print(f"Database connection error: {str(e)}")
        raise

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

        return cors_response(200, {
            "message": "Style preferences updated successfully",
            "preferences": updated_preferences
        })

    except Exception as e:
        print(f"Error in putStylePreferences: {str(e)}")
        return cors_response(500, {"error": f"Error updating style preferences: {str(e)}"})

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
            return cors_response(200, {
                "message": "Style preferences retrieved successfully",
                "preferences": preferences
            })
        else:
            return cors_response(404, {"error": "Style preferences not found for this user"})

    except Exception as e:
        print(f"Error in getStylePreferences: {str(e)}")
        return cors_response(500, {"error": f"Error retrieving style preferences: {str(e)}"})

############
def generateOutfitRec(event, context):
    try:        
        userId = event['pathParameters'].get('userId')
        if not userId:
            return cors_response(400, "userId is required in path parameters")
        
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
                    return cors_response(404, "User preferences not found")

                user_preferences = user_preferences_row.get('preferences', {})

                # Get user's wardrobe (liked posts)
                cursor.execute("""
                    SELECT p.* FROM posts p
                    JOIN likedPost lp ON p.id = lp.postId
                    WHERE lp.userId = %s
                """, (userId,))
                wardrobe = cursor.fetchall()

                if not wardrobe:
                    return cors_response(404, "User has no liked posts to generate outfit from")

                # Here you would implement your outfit generation logic
                # For this example, we'll just return a random selection of items
                outfit = random.sample(wardrobe, min(2, len(wardrobe)))

        return cors_response(200, {
            "message": "Outfit recommendation generated",
            "outfit": outfit
        })

    except Exception as e:
        return cors_response(500, f"Error generating outfit recommendation: {str(e)}")
    
############
def generateItemRec(event, context):
    try:        
        userId = event['pathParameters'].get('userId')
        if not userId:
            return cors_response(400, "userId is required in path parameters")
        
        body = event.get('body', '{}')
        if isinstance(body, str):
            body = json.loads(body)
        elif body is None:
            body = {}
        
        category = body.get('category')
        if not category:
            return cors_response(400, "category is required in request body")

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get user preferences
                cursor.execute("SELECT preferences FROM aiStyler WHERE userId = %s", (userId,))
                user_preferences_row = cursor.fetchone()

                if not user_preferences_row:
                    return cors_response(404, "User preferences not found")

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

        return cors_response(200, {
            "message": "Item recommendations generated",
            "items": recommended_items
        })

    except Exception as e:
        return cors_response(500, f"Error generating item recommendations: {str(e)}")

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
                
        return cors_response(200, {
            "message": "Style analysis generated",
            "analysis": analysis
        })

    except Exception as e:
        print(f"Error in getStyleAnalysis: {str(e)}")
        return cors_response(500, f"Error generating style analysis: {str(e)}")

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

        return cors_response(200, {
            "message": "Trending items retrieved",
            "items": trending_items
        })

    except Exception as e:
        print(f"Error in getTrendingItems: {str(e)}")
        return cors_response(500, f"Error retrieving trending items: {str(e)}")

############
def getSimilarItems(event, context):
    try:
        postId = event['pathParameters']['postId']

        if not postId:
            return cors_response(400, "postId is required")

        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get the original post
                cursor.execute("SELECT * FROM posts WHERE id = %s", (postId,))
                original_post = cursor.fetchone()

                if not original_post:
                    return cors_response(404, "Original post not found")

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

        return cors_response(200, {
            "message": "Similar items retrieved",
            "items": similar_items
        })

    except Exception as e:
        print(f"Error in getSimilarItems: {str(e)}")
        return cors_response(500, f"Error retrieving similar items: {str(e)}")

###########
def generateOutfitByWardrobe(event, context):
    try:        
        userId = event['pathParameters'].get('userId')
        if not userId:
            return cors_response(400, "userId is required in path parameters")
        
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
                    return cors_response(404, "User has no liked posts to generate outfit from")

                # Here you would implement your outfit generation logic
                # For this example, we'll just return a random selection of items
                outfit = random.sample(wardrobe, min(2, len(wardrobe)))

        return cors_response(200, {
            "message": "Outfit generated from wardrobe",
            "outfit": outfit
        })

    except json.JSONDecodeError as e:
        return cors_response(400, f"Invalid JSON in request body: {str(e)}")
    except Exception as e:
        return cors_response(500, f"Error generating outfit from wardrobe: {str(e)}")

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
                    return cors_response(404, "User preferences not found")

                # Generate style tips based on user preferences
                # This is a placeholder - implement your own logic for generating tips
                tips = [
                    "Mix and match patterns for a bold look",
                    "Incorporate more color into your wardrobe",
                    "Experiment with layering different textures",
                    "Try accessorizing with statement pieces",
                    "Invest in versatile, classic pieces"
                ]
        
        return cors_response(200, {
            "message": "Style tips retrieved",
            "tips": tips
        })

    except Exception as e:
        print(f"Error in getStyleTips: {str(e)}")
        return cors_response(500, f"Error retrieving style tips: {str(e)}")

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

        return cors_response(200, {
            "message": "Styler refreshed successfully",
            "updatedStyler": updated_styler
        })

    except Exception as e:
        print(f"Error in refreshStyler: {str(e)}")
        return cors_response(500, f"Error refreshing styler: {str(e)}")