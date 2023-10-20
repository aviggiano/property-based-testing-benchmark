from typing import List
import logging
import boto3
import json
from os import environ

def send_message(obj: json, local=False) -> str:
    msg = json.dumps(obj)
    logging.info(msg)
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
            message_id = str(len(queue))
    else:
        sqs = boto3.client('sqs', region_name='us-east-1')
        response = sqs.get_queue_url(QueueName=environ['SQS_QUEUE_NAME'])
        queue_url = response['QueueUrl']
        response = sqs.send_message(
            QueueUrl=queue_url,
            DelaySeconds=10,
            MessageBody=msg
        )
        message_id = response['MessageId']
    logging.info(message_id)
    return message_id

def full_benchmark(local=False) -> List[str]:
    tools = ['halmos', 'foundry']
    projects = ['abdk-math-64x64']
    mutants = ['']
    ans = []
    for tool in tools:
        for project in projects:
            for mutant in mutants:
                obj = {
                    "tool": tool,
                    "project": project,
                    "test": "test_",
                    "mutant": mutant
                }
                message_id = send_message(obj, local)
                ans.append(message_id)
    return ans