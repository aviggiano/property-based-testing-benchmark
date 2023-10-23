from typing import List
import logging
import boto3
import json
from os import environ, chdir
from .cmd import cmd
from .runner import get_functions


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
    tools = ['halmos', 'foundry', 'echidna', 'medusa']
    projects = ['abdk-math-64x64']
    ans = []
    for project in projects:
        chdir('projects/{}'.format(project))
        functions = get_functions()
        for tool in tools:
            for test in functions:
                mutants = get_mutants(test)
                for mutant in mutants:
                    preprocess = 'git apply {}.patch && cd lib/abdk-libraries-solidity && git apply ../../mutants/{}.patch && cd ../../'.format(
                        tool, mutant)
                    obj = {
                        "tool": tool,
                        "project": project,
                        'preprocess': preprocess,
                        "test": test,
                        "timeout": 3600,
                        "mutant": mutant,
                    }
                    message_id = send_message(obj, local)
                    ans.append(message_id)
        chdir('../..')
    return ans


def get_mutants(test: str) -> List[str]:
    status, fun, stderr = cmd(
        "find mutants | sed 's/mutants\/\(.*\)\-.*/\\1/'")
    mutants = []
    for base_test in fun.split('\n'):
        if base_test in test:
            status, mutant, stderr = cmd(
                "find mutants | grep {} | sed 's/mutants\/\(.*\)\.patch/\\1/'".format(base_test))
            mutants = mutant.split('\n')
            break
    return mutants
