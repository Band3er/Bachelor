import json
import boto3
import hashlib
import hmac
import base64

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Users')

def verify_password(password: str, stored_hash: str) -> bool:
    try:
        decoded = base64.b64decode(stored_hash.encode())
        salt = decoded[:16]
        stored_password_hash = decoded[16:]
        test_hash = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 100_000)
        return hmac.compare_digest(test_hash, stored_password_hash)
    except Exception as e:
        print(f"Hash verification error: {e}")
        return False

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        email = body.get('email')
        password = body.get('password')

        if not email or not password:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'email și password sunt necesare'})
            }

        # Caută utilizatorul după email
        result = table.scan(
            FilterExpression='email = :e',
            ExpressionAttributeValues={':e': email}
        )

        if not result['Items']:
            return {
                'statusCode': 401,
                'body': json.dumps({'error': 'Email sau parolă incorectă'})
            }

        user = result['Items'][0]
        stored_hash = user['passwordHash']

        if not verify_password(password, stored_hash):
            return {
                'statusCode': 401,
                'body': json.dumps({'error': 'Email sau parolă incorectă'})
            }

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Autentificare reușită',
                'id': user['id'],
                'esp_mac': user.get('esp_mac', None)
            })
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Eroare server: {str(e)}'})
        }
