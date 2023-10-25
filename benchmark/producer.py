from typing import List
import logging
import boto3
import json
import argparse
import time
from os import environ, chdir
from .cmd import cmd
from .runner import get_functions


def send_message(args: dict) -> str:
    msg = json.dumps(args.send_message)
    logging.info(msg)
    if args.local:
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


def full_benchmark(args: dict) -> List[str]:
    version = time.strftime("%s")
    # tools = ['halmos', 'foundry', 'echidna', 'medusa']
    # NOTE only halmos for now
    tools = ['halmos', 'foundry']
    projects = ['abdk-math-64x64']
    ans = []
    for project in projects:
        chdir('projects/{}'.format(project))
        functions = get_functions()
        all_mutants = get_all_mutants()
        for tool in tools:
            for test in functions:
                mutants = get_mutants_by_test(all_mutants, test)
                for mutant in mutants:
                    preprocess = 'git apply {}.patch && cd lib/abdk-libraries-solidity && git apply ../../mutants/{}.patch && cd ../../'.format(
                        tool, mutant)
                    postprocess = 'git checkout . && cd lib/abdk-libraries-solidity && git checkout . && cd ../../'
                    msg = {
                        "tool": tool,
                        "project": project,
                        'preprocess': preprocess,
                        'postprocess': postprocess,
                        "test": test,
                        "timeout": 3600,
                        "mutant": mutant,
                        "prefix": "{}-".format(version)
                    }
                    print(args)
                    ns = argparse.Namespace()
                    ns.send_message = msg
                    ns.local = args.local
                    message_id = send_message(ns)
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
                "find mutants | grep '\\b{}\\b' | sed 's/mutants\/\(.*\)\.patch/\\1/'".format(mutant))
            mutants_by_test += stdout.split('\n')
    return list(set(mutants_by_test))
