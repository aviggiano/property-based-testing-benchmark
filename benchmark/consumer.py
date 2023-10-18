from os import environ
import time
import json
import boto3

def handle_message(body: str):
    print("Received message: ", body)

def poll_messages(local=False):
    if local:
        with open('queue.json', 'a+') as f:
            f.seek(0)
            f.close()
        with open('queue.json', 'r+') as f:
            content = f.read()
            if content != '':
                queue = json.loads(content)
                while len(queue) > 0:
                    msg = queue.pop()
                    handle_message(msg)
                f.truncate(0)
            f.close()
    else:
        sqs = boto3.resource("sqs")
        queue = sqs.get_queue_by_name(QueueName=environ['SQS_QUEUE_NAME'])

        while True:
            messages = queue.receive_messages(
                MaxNumberOfMessages=1,
                WaitTimeSeconds=1
            )
            for message in messages:
                try:
                    handle_message(message.body)
                except Exception as e:
                    print(f"Exception while processing message: {repr(e)}")
                    continue

                message.delete()

