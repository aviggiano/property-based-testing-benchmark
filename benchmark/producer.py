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


def full_benchmark_abdk_math_64x64(args: dict) -> List[str]:
    version = time.strftime("%s")
    # tools = ['halmos', 'foundry', 'echidna', 'medusa']
    tools = ['halmos', 'foundry']
    projects = ['abdk-math-64x64']
    ans = []
    for project in projects:
        chdir('projects/{}'.format(project))
        functions = get_functions()
        filter_functions = ['test_abs_multiplicativeness', 'test_exp_inverse', 'test_exp_negative_exponent', 'test_exp_2_inverse', 'test_exp_2_negative_exponent', 'test_inv_double_inverse', 'test_inv_division_noncommutativity',
                            'test_inv_multiplication', 'test_inv_identity', 'test_mul_associative', 'test_mul_distributive', 'test_mul_values', 'test_sqrt_inverse_mul', 'test_sqrt_inverse_pow', 'test_sqrt_distributive']
        functions = [f for f in functions if f not in filter_functions]

        all_mutants = get_all_mutants()
        for tool in tools:
            for test in functions:
                mutants = get_mutants_by_test(all_mutants, test)
                for mutant in mutants:
                    preprocess = 'forge clean && git apply {}.patch --allow-empty && cd lib/abdk-libraries-solidity && git apply ../../mutants/{}.patch && git diff && cd ../../'.format(
                        tool, mutant)
                    postprocess = 'git checkout . && cd lib/abdk-libraries-solidity && git checkout . && cd ../../'
                    msg = {
                        "tool": tool,
                        "project": project,
                        'preprocess': preprocess,
                        'postprocess': postprocess,
                        'extra_args': '',
                        'contract': '',
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


def full_benchmark(args: dict) -> List[str]:
    version = time.strftime("%s")
    ans = []
    tools = ['halmos', 'foundry', 'echidna', 'medusa']
    loops = ['2', '3', '4']
    for tool in tools:
        i = 0
        for loop in loops:
            if tool != 'halmos' and i > 0:
                continue
            i += 1
            extra_args = tool_cmd(tool, loop)
            msg = {
                "tool": tool,
                "project": 'dai-certora',
                'preprocess': '',
                'postprocess': '',
                'contract': '',
                'extra_args': extra_args,
                "test": 'check_minivat_n_full_symbolic',
                "timeout": 3600,
                "mutant": '',
                "prefix": "{}-".format(version)
            }
            print(args)
            ns = argparse.Namespace()
            ns.send_message = msg
            ns.local = args.local
            message_id = send_message(ns)
            ans.append(message_id)
    print('{} benchmark jobs created'.format(len(ans)))
    return ans


def get_all_mutants() -> List[str]:
    status, stdout, stderr = cmd(
        "find mutants | sed 's/mutants\/\(.*\)\-.*/\\1/'")
    return stdout.split('\n')


def tool_cmd(tool: str, loop: str) -> str:
    if tool == 'halmos':
        return 'halmos --function check_minivat_n_full_symbolic --contract HalmosTester -vvv --solver-parallel --solver-timeout-assertion 0 --loop {}'.format(loop)
    elif tool == 'foundry':
        return 'forge test --match-contract FoundryTester'
    elif tool == 'medusa':
        return 'medusa fuzz --no-color'
    elif tool == 'echidna':
        return 'echidna . --contract CryticTester --config config.yaml'
    else:
        raise Exception("Unknown tool {}".format(tool))


def get_mutants_by_test(all_mutants: List[str], test: str) -> List[str]:
    mutants_by_test = []
    for mutant in all_mutants:
        if mutant in test:
            status, stdout, stderr = cmd(
                "find mutants | grep '\\b{}\\b' | sed 's/mutants\/\(.*\)\.patch/\\1/'".format(mutant))
            mutants_by_test += stdout.split('\n')
    return list(set(mutants_by_test))
