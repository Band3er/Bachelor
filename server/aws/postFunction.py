import json
import boto3
import time

dynamodb = boto3.client('dynamodb')
dynamodb_resource = boto3.resource('dynamodb')
table = dynamodb_resource.Table('Devices')

def lambda_handler(event, context):
    try:
        method = event.get("requestContext", {}).get("http", {}).get("method")
        print("HTTP Method:", method)
        print("Raw event:", json.dumps(event))

        if method == "POST":
            body = json.loads(event.get('body', '{}'))

            item = {
                'id': {'N': str(body['id'])},
                'online': {'N': str(body['online'])},
                'ip': {'S': body['ip']},
                'mac': {'S': body['mac']},
                'esp_mac': {'S': body['esp_mac']},
                'timestamp': {'S': str(body['timestamp'])},
                'TTL': {'S': str(body['TTL'])}
            }

            response = dynamodb.put_item(
                TableName="Devices",
                Item=item
            )

            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Connection': 'close'
                },
                'body': json.dumps('Get with success: ')
            }
        else:
            return {
                'statusCode': 405,
                'body': json.dumps(f'Method {method} not allowed')
            }
    except Exception as e:
        print("Global error:", e)
        return {
            'statusCode': 500,
            'body': json.dumps(f'Unhandled error: {str(e)}')
        }