import boto3
from boto3.dynamodb.conditions import Key
from os import getenv
from uuid import uuid4
import json
 
region_name = getenv('APP_REGION')
users_table = boto3.resource('dynamodb', region_name=region_name ).Table('users')
 
def lambda_handler(event, context):
    
    body = json.loads(event['body'])
    email = event["pathParameters"]["email"]
    password = body["password"]
        
    res = users_table.query(
        IndexName="email-index",  # Name of the GSI
        KeyConditionExpression=Key('email').eq(email)
    )


    if "Items" in res:
        user = res["Items"][0]
        if user["password"] == password:
            return response(200, user)
        else:
            return response(502, "bad creds")
    else:
        return response(502, user)

def response(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json"
            },
        "body": json.dumps(body)
    }