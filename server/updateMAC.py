import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Users')

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        user_id = body.get('id')
        esp_mac = body.get('esp_mac')

        if not user_id or not esp_mac:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'id și esp_mac sunt necesare'})
            }

        table.update_item(
            Key={'id': user_id},
            UpdateExpression="SET esp_mac = :mac",
            ExpressionAttributeValues={':mac': esp_mac}
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'esp_mac salvat'})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Eroare server: {str(e)}'})
        }
