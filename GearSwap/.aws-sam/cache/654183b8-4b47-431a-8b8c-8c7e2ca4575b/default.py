import json
import traceback

def lambda_handler(event, context):
    print("Default Lambda triggered - logging all details")
    print("=" * 80)
    
    try:
        # Log the entire event
        print("Full event:")
        print(json.dumps(event, indent=2))
        
        # Log specific important parts
        print("\nKey components:")
        
        # Request context
        if 'requestContext' in event:
            print("\nRequest Context:")
            print(f"Connection ID: {event['requestContext'].get('connectionId', 'Not found')}")
            print(f"Route Key: {event['requestContext'].get('routeKey', 'Not found')}")
            print(f"Event Type: {event['requestContext'].get('eventType', 'Not found')}")
            print(f"API ID: {event['requestContext'].get('apiId', 'Not found')}")
        
        # Message body
        if 'body' in event:
            print("\nMessage Body:")
            try:
                body = json.loads(event['body'])
                print("Parsed body:")
                print(json.dumps(body, indent=2))
            except json.JSONDecodeError:
                print("Raw body (not JSON):")
                print(event['body'])
        
        # Headers if present
        if 'headers' in event:
            print("\nHeaders:")
            print(json.dumps(event['headers'], indent=2))

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Message logged in default route',
                'connectionId': event['requestContext'].get('connectionId', 'unknown')
            })
        }

    except Exception as e:
        print("Error in default handler:")
        print(str(e))
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }