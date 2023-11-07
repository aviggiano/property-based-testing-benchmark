from os import environ
from .cmd import cmd
import logging
import time
import json
import boto3


class RunTaskException(Exception):
    pass


def handle_message(body: str, local: bool) -> str:
    logging.info("Received message: " + str(body))
    data = json.loads(body)
    if local:
        cmd("python3 -m benchmark runner --preprocess {} --postprocess {} --tool {} --project {} --test {} --contract {} --mutant {} --timeout {} --prefix {} --extra-args {}".format(data["preprocess"], data["postprocess"],
            data["tool"], data["project"], data["test"], data["contract"], data["mutant"], data["timeout"], data["prefix"], data["extra_args"]))
        return ''
    else:
        ecs = boto3.client('ecs')
        logging.info('Running task')
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
                        'command': [
                            "--", "runner", "--preprocess", data["preprocess"], "--postprocess", data["postprocess"], "--tool", data["tool"], "--project", data[
                                "project"], "--test", data["test"], "--contract", data["contract"], "--mutant", data["mutant"], "--timeout", str(data["timeout"]), "--prefix", data["prefix"], "--extra-args", data["extra_args"]
                        ],
                    }
                ]
            },
            count=1,
            platformVersion='LATEST',
        )
        tasks = response.get('tasks', [])
        if (len(tasks) > 0):
            task_arn = tasks.pop().get('taskArn', '')
            logging.info(task_arn)
            return task_arn
        else:
            raise RunTaskException('No tasks returned')


def delete_message(message):
    logging.info("Deleting message: " + message.body)
    message.delete()


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


def poll_messages(args: dict):
    if args.queue_statistics:
        return get_queue_statistics(args.local)

    if args.start_runner is not None:
        return handle_message(json.dumps(args.start_runner), args.local)

    if args.local:
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
                        handle_message(msg, args.local)
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
                    task_arn = handle_message(message.body, args.local)
                    delete_message(message)
                except RunTaskException:
                    logging.info(
                        "Retrying message after queue visibility timeout")
                except Exception as e:
                    logging.critical(e, exc_info=True)
                    delete_message(message)
                    continue
