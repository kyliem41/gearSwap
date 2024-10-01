import boto3
from boto3.dynamodb.conditions import Key
from os import getenv
from uuid import uuid4
import json
from datetime import datetime

region_name = getenv('APP_REGION')
users_table = boto3.resource('dynamodb', region_name=region_name).Table('users')

def lambda_handler(event, context):
    userId = str(uuid4())
    body = json.loads(event['body'])
    username = body['username']
    email = body['email']
    password = body['password']
    profileInfo = body['profileInfo']
    
    db_insert(userId, username, email, password, profileInfo)
 
    return response(200, {"Id": userId})

def db_insert(userId, username, email, password, profileInfo):
    
    date = datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%f')
    likeCount = ;
    saveCount = ;
    
    users_table.put_item(Item={
        'Id': userId,
        'username': username, #must be unique
        'email': email, #must be unique
        'password': password,
        'profileInfo': profileInfo,
        'joinDate': date,
        'likeCount': likeCount,
        'saveCount': saveCount
    })
    
def response(code, body):
    return {
        "statusCode": code,
        "headers": {
            'Content-Type': 'application/json'
        },
        "body": json.dumps(body)
    }