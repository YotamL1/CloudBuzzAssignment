import json
import boto3


def lambda_handler(event, context):
    num = 0
    try:
        num = (int(event['Key1'])) + (int(event['Key2']))
        res = f'the number is:{num}'
        statusCode = 200

        client = boto3.client('sns')
        response = client.publish(
            TargetArn='arn:aws:sns:us-east-1:582091735727:Hello',
            Message=json.dumps({'default': json.dumps(num)}),
            MessageStructure='json'
        )
    except:
        res = 'please enter number as parameters'
        statusCode = 400

    return {
        'statusCode': statusCode,
        'body': json.dumps(res)
    }