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

        if method == "GET":
            query_params = event.get('queryStringParameters') or {}
            target_mac = query_params.get('mac')

            if not target_mac:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'MAC parameter is missing'})
                }

            max_retries = 10
            retries = 0
            items = []

            while not items and retries < max_retries:
                response = dynamodb.scan(
                    TableName="Devices",
                    FilterExpression='esp_mac = :target_mac',
                    ExpressionAttributeValues={
                        ':target_mac': {'S': target_mac}
                    }
                )
                items = response.get('Items', [])
                if not items:
                    time.sleep(1)
                    retries += 1

            result = []
            for item in items:
                result.append({
                    'id': item.get('id', {}).get('N'),
                    'online': item.get('online', {}).get('N'),
                    'ip': item.get('ip', {}).get('S'),
                    'mac': item.get('mac', {}).get('S')
                })

            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Connection': 'close'
                },
                'body': json.dumps(result)
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