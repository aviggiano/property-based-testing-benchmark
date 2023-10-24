from os import environ
from .cmd import cmd
import logging
import time
import json
import boto3


def handle_message(body: str, local: bool):
    print("Received message: ", body)
    data = json.loads(body)
    if local:
        cmd("python3 -m benchmark runner --preprocess {} --tool {} --project {} --test {} --mutant {} --timeout {} --prefix {}".format(data["preprocess"],
            data["tool"], data["project"], data["test"], data["mutant"], data["timeout"], data["prefix"]))
    else:
        ecs = boto3.client('ecs')
        response = ecs.run_task(
            cluster=environ['ECS_CLUSTER_NAME'],
            launchType='FARGATE',
            taskDefinition=environ['ECS_RUNNER_TASK_DEFINITION'],
            networkConfiguration={
                'awsvpcConfiguration': {
                    'subnets': environ['ECS_SUBNETS'].split(','),
                    'securityGroups': environ['ECS_SECURITY_GROUP'].split(','),
                    'assignPublicIp': 'DISABLED'
                }
            },
            overrides={
                'containerOverrides': [
                    {
                        'name': environ['ECS_CONTAINER_NAME'],
                        'command': ["--", "runner", "--preprocess", data["preprocess"], "--tool", data["tool"], "--project", data["project"], "--test", data["test"], "--mutant", data["mutant"], "--timeout", data["timeout"], "--prefix", data["prefix"]],
                    }
                ]
            },
            count=1,
            platformVersion='LATEST',
        )
        tasks = response.get('tasks', [])
        if (len(tasks) > 0):
            logging.info(tasks.pop().get('taskArn', ''))
        else:
            raise Exception('No tasks created')


def get_queue_statistics(local=False):
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
            logging.info(len(queue))
            f.close()
    else:
        sqs = boto3.resource("sqs")
        queue = sqs.get_queue_by_name(QueueName=environ['SQS_QUEUE_NAME'])
        attributes = queue.attributes
        logging.info('{}/{}'.format(attributes.get('ApproximateNumberOfMessages'),
                     attributes.get('ApproximateNumberOfMessagesNotVisible')))


def poll_messages(start_runner: json, queue_statistics: bool, local=False):
    if queue_statistics:
        return get_queue_statistics(local)

    if start_runner is not None:
        return handle_message(json.dumps(start_runner), local)

    if local:
        while True:
            with open('queue.json', 'a+') as f:
                f.seek(0)
                f.close()
            with open('queue.json', 'r+') as f:
                content = f.read()
                if content != '':
                    queue = json.loads(content)
                    while len(queue) > 0:
                        msg = queue.pop()
                        handle_message(msg, local)
                    f.truncate(0)
                f.close()
            time.sleep(1)
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
                    handle_message(message.body, local)
                    # TODO should we delete failed messages from queue or not?
                    # if you want to delete them, move this to the end of the try/except block
                    message.delete()
                except Exception as e:
                    print(f"Exception while processing message: {repr(e)}")
                    time.sleep(10)
                    continue
