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
            # print(queue)
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
    # tools = ['halmos', 'foundry', 'echidna', 'medusa']
    # NOTE only halmos for now
    tools = ['halmos']
    projects = ['abdk-math-64x64']
    ans = []
    for project in projects:
        chdir('projects/{}'.format(project))
        functions = get_functions()
        # NOTE get only test_add functions
        functions = [f for f in functions if 'test_add' in f]
        all_mutants = get_all_mutants()
        for tool in tools:
            for test in functions:
                mutants = get_mutants_by_test(all_mutants, test)
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
                        "prefix": "v2-"
                    }
                    message_id = send_message(obj, local)
                    ans.append(message_id)
        chdir('../..')
    print('{} benchmark jobs created'.format(len(ans)))
    return ans


def get_all_mutants() -> List[str]:
    status, stdout, stderr = cmd(
        "find mutants | sed 's/mutants\/\(.*\)\-.*/\\1/'")
    return stdout.split('\n')


def get_mutants_by_test(all_mutants: List[str], test: str) -> List[str]:
    mutants_by_test = []
    for mutant in all_mutants:
        if mutant in test:
            status, stdout, stderr = cmd(
                "find mutants | grep {} | sed 's/mutants\/\(.*\)\.patch/\\1/'".format(mutant))
            mutants_by_test = stdout.split('\n')
            break
    return mutants_by_test
