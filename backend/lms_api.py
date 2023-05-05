import json

def lambda_handler(event, context):
    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": "Hello, World!"
        })
    }
    return response
