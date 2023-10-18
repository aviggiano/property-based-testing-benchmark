from os import environ
import time
import json
from aws_sqs_consumer import Consumer, Message

def handle(message: Message):
    print("Received message: ", message.Body)

class SimpleConsumer(Consumer):
    def handle_message(self, message: Message):
        return handle(message)

def mk_consumer(local=False) -> SimpleConsumer:
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
                    dict = json.loads(msg)
                    handle(Message(Body=dict['Body']))
                f.truncate(0)
            f.close()
    else:
        consumer = SimpleConsumer(
            queue_url=environ['SQS_URL'],
            polling_wait_time_ms=5
        )
        consumer.start()
        return consumer
