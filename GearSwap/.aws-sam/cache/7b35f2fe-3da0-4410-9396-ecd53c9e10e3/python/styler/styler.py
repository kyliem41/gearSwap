import os
import json
import boto3
import openai
from typing import List, Dict, Any
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime
import traceback
from config_manager import config_manager

class FashionGPTRecommender:
    def __init__(self, db_connection):
        self.db = db_connection
        self.openai = openai
        self.openai.api_key = config_manager.get_parameter('OPENAI_API_KEY')
        self.fine_tuned_model = config_manager.get_parameter('FINE_TUNED_MODEL_ID')
        
    async def prepare_training_data(self, user_id: int) -> List[Dict]:
        """Prepare training data from user's history"""
        with self.db.cursor(cursor_factory=RealDictCursor) as cursor:
            # Get user's liked posts
            cursor.execute("""
                SELECT p.*, lp.dateLiked 
                FROM posts p
                JOIN likedPost lp ON p.id = lp.postId
                WHERE lp.userId = %s
                ORDER BY lp.dateLiked DESC
            """, (user_id,))
            liked_posts = cursor.fetchall()
            
            # Get user's outfits
            cursor.execute("""
                SELECT * FROM outfit 
                WHERE userId = %s
                ORDER BY dateCreated DESC
            """, (user_id,))
            outfits = cursor.fetchall()
            
            # Get user's search history
            cursor.execute("""
                SELECT * FROM search
                WHERE userId = %s
                ORDER BY timestamp DESC
                LIMIT 50
            """, (user_id,))
            searches = cursor.fetchall()
            
            # # Get user's interests
            # cursor.execute("""
            #     SELECT * FROM interest
            #     WHERE userId = %s
            # """, (user_id,))
            # interests = cursor.fetchall()
            
            # Get user's styler preferences
            cursor.execute("""
                SELECT preferences FROM styler
                WHERE userId = %s
            """, (user_id,))
            styler_prefs = cursor.fetchone()

        # Create training examples
        training_examples = []
        
        # Example format for outfit recommendations
        for outfit in outfits:
            training_examples.append({
                "messages": [
                    {"role": "system", "content": "You are a fashion AI stylist. Use the user's style preferences and history to make personalized recommendations."},
                    {"role": "user", "content": "I need an outfit recommendation based on my style."},
                    {"role": "assistant", "content": f"Based on your preferences, I recommend an outfit which includes {outfit['items']}."}##similar to your creation '{outfit['name']}' which includes {outfit['items']}. This matches your style as shown in your liked items and aligns with your interests in {[interest['name'] for interest in interests]}."}
                ]
            })
            
        # Examples for style recommendations
        for liked_post in liked_posts:
            training_examples.append({
                "messages": [
                    {"role": "system", "content": "You are a fashion AI stylist. Recommend items based on user preferences."},
                    {"role": "user", "content": f"Find me items similar to this {liked_post['category']} in my size {liked_post['size']}."},
                    {"role": "assistant", "content": f"I recommend looking for {liked_post['category']} items with similar characteristics: {liked_post['tags']}. These match your style preferences and would work well with your existing wardrobe."}
                ]
            })

        return training_examples

    async def fine_tune_model(self, training_data: List[Dict]) -> str:
        """Fine-tune GPT model with fashion data"""
        try:
            # Upload training data
            training_file = await self.openai.File.acreate(
                file=json.dumps(training_data),
                purpose='fine-tune'
            )

            # Create fine-tuning job
            fine_tuning_job = await self.openai.FineTuningJob.acreate(
                training_file=training_file.id,
                model="gpt-4",
                hyperparameters={
                    "n_epochs": 3
                }
            )

            return fine_tuning_job.id
        except Exception as e:
            print(f"Error in fine-tuning: {str(e)}")
            raise

    async def get_recommendation(self, user_id: str, request_type: str, message: str, context: list) -> dict:
        """Get personalized recommendations using fine-tuned model"""
        try:
            # Get user context
            with self.db.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get user preferences and history
                cursor.execute("""
                    SELECT p.*, lp.dateLiked 
                    FROM posts p
                    JOIN likedPost lp ON p.id = lp.postId
                    WHERE lp.userId = %s
                    ORDER BY lp.dateLiked DESC
                    LIMIT 10
                """, (user_id,))
                recent_likes = cursor.fetchall()
                
                cursor.execute("""
                    SELECT preferences FROM styler
                    WHERE userId = %s
                """, (user_id,))
                styler_prefs = cursor.fetchone()

            # Prepare context for the model
            user_context = {
                "style_preferences": styler_prefs['preferences'] if styler_prefs else {},
                "recent_likes": [
                    {
                        "category": post['category'],
                        "tags": post['tags'],
                        "size": post['size']
                    } for post in recent_likes
                ]
            }

            # Get recommendation from model using new OpenAI API format
            response = await self.client.chat.completions.create(
                model=self.fine_tuned_model,
                messages=[
                    {"role": "system", "content": "You are a fashion AI stylist with expertise in personal style recommendations."},
                    {"role": "user", "content": message},
                    {"role": "assistant", "content": f"I'll help you with your {request_type} request. Here's what I know about your style: {json.dumps(user_context)}"}
                ]
            )

            # Extract the response text - updated for new API format
            recommendation = response.choices[0].message.content

            return {
                'recommendation': recommendation,
                'context': {
                    'type': request_type,
                    'user_id': user_id,
                    'timestamp': datetime.now().isoformat()
                }
            }
            
        except Exception as e:
            print(f"Error in get_recommendation: {str(e)}")
            traceback.print_exc()  # Now properly imported
            raise

    def _create_outfit_prompt(self, user_context: Dict, occasion: str = None) -> str:
        return f"""Based on the following user preferences and style history:
        - Style preferences: {json.dumps(user_context['style_preferences'])}
        - Recent liked items: {json.dumps(user_context['recent_likes'])}
        
        Please recommend a complete outfit{f' for {occasion}' if occasion else ''} that matches their style."""

    def _create_item_prompt(self, user_context: Dict, category: str) -> str:
        return f"""Based on the following user preferences and style history:
        - Style preferences: {json.dumps(user_context['style_preferences'])}
        - Recent liked items: {json.dumps(user_context['recent_likes'])}
        
        Please recommend {category} items that would match their style and existing wardrobe."""

    def _create_style_prompt(self, user_context: Dict) -> str:
        return f"""Based on the following user preferences and style history:
        - Style preferences: {json.dumps(user_context['style_preferences'])}
        - Recent liked items: {json.dumps(user_context['recent_likes'])}
        
        Please provide style tips and suggestions for improving their wardrobe."""

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

async def lambda_handler(event, context):
    if event['httpMethod'] == 'OPTIONS':
        return cors_response(200, {'message': 'OK'})
    
    try:
        conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            port=os.environ['DB_PORT'],
        )

        recommender = FashionGPTRecommender(conn)
        
        auth_header = event.get('headers', {}).get('Authorization')
        if not auth_header:
            return cors_response(401, {'error': 'No authorization header'})

        resource = event['resource']
        method = event['httpMethod']

        if event['resource'] == '/styler/outfit/{userId}' and method == 'POST':
            user_id = event['pathParameters']['userId']
            body = json.loads(event['body'])
            
            recommendation = await recommender.get_recommendation(
                user_id=user_id,
                request_type="outfit",
                occasion=body.get('occasion')
            )
            
            return cors_response(200, recommendation)

        elif event['resource'] == '/styler/item/{userId}' and method == 'POST':
            user_id = event['pathParameters']['userId']
            body = json.loads(event['body'])
            
            recommendation = await recommender.get_recommendation(
                user_id=user_id,
                request_type="item",
                category=body.get('category')
            )
            
            return cors_response(200, recommendation)

        return cors_response(405, {'error': 'Method not allowed'})
    
    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return cors_response(500, {'error': str(e)})

    finally:
        if conn:
            conn.close()