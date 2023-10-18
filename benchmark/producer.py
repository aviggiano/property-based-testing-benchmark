import boto3
import json
from os import environ

def send_message(msg, local=False) -> str:
    if local:
        with open('queue.json', 'a+') as f:
            f.seek(0)
            f.close()
        with open('queue.json', 'r+') as f:
            content = f.read()
            if content != '':
                queue = json.loads(content)
            else:
                queue = []
            queue.append(msg)
            print(queue)
            f.seek(0)
            f.write(json.dumps(queue))
            f.close()
            return str(len(queue))
    else:
        sqs = boto3.client('sqs', region_name='us-east-1')
        queue_url = environ['SQS_URL']
        response = sqs.send_message(
            QueueUrl=queue_url,
            DelaySeconds=10,
            MessageBody=msg
        )
    return response['MessageId']