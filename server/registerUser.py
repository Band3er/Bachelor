import json
import uuid
import time
import boto3
import hashlib
import hmac
import os
import base64

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Users')  # asigura-te ca tabela exista

def hash_password(password: str, salt: bytes = None):
    if not salt:
        salt = os.urandom(16)
    hash_bytes = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 100_000)
    hash_encoded = base64.b64encode(salt + hash_bytes).decode()
    return hash_encoded

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        email = body.get('email')
        password = body.get('password')
        esp_mac = body.get('esp_mac')

        if not email or not password:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'email si password sunt necesare'})
            }

        # Verificare daca userul deja exista
        existing = table.scan(
            FilterExpression='email = :e',
            ExpressionAttributeValues={':e': email}
        )

        if existing['Items']:
            return {
                'statusCode': 409,
                'body': json.dumps({'error': 'Email deja inregistrat'})
            }

        user_id = str(uuid.uuid4())
        password_hash = hash_password(password)

        table.put_item(Item={
            'id': user_id,
            'email': email,
            'passwordHash': password_hash,
            'createdAt': int(time.time()),
            'esp_mac': esp_mac or None
        })

        return {
            'statusCode': 201,
            'body': json.dumps({'message': 'Utilizator creat', 'id': user_id})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Eroare server: {str(e)}'})
        }
