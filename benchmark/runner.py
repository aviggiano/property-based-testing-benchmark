from typing import List
import uuid
from os import chdir
import logging
import json
from .cmd import cmd
from .storage import put_object
from shlex import quote, split
from timeit import default_timer as timer


def run_benchmark(preprocess: str, tool: str, project: str, test: str, mutant: str, timeout: int, local=False):
    job_id = str(uuid.uuid4())

    chdir('projects/{}'.format(quote(project)))
    contract = get_contract(test)

    for fun in get_functions():
        if fun.startswith(test) == False:
            # https://stackoverflow.com/questions/5694228/sed-in-place-flag-that-works-both-on-mac-bsd-and-linux
            # NOTE: this only works on GNU sed
            cmd("find test -type f -exec sed -i -e 's/\(" +
                fun + ".*\)public/\\1private/' \{\} \;")

    output_filename = '{}-output.json'.format(job_id)
    output = ''
    with open(output_filename, 'a+') as f:
        f.close()

    mutant_cmd = 'true'
    if mutant != '':
        mutant_cmd = 'git apply mutants/{}.patch'.format(quote(mutant))

    tool_cmd = 'timeout -k 10 {} '.format(timeout)
    if tool == 'halmos':
        tool_cmd += "halmos --statistics --json-output {} --solver-parallel --test-parallel --function {} --contract {}".format(
            output_filename, quote(test), contract)
    elif tool == 'foundry':
        tool_cmd += "forge test --match-test {}".format(quote(test))
    elif tool == 'echidna':
        cmd('echo ' + '\'filterFunctions: [\"{}.setUp()\",\"{}.excludeSenders()\",\"{}.targetInterfaces()\",\"{}.targetSenders()\",\"{}targetContracts.()\",\"{}.targetArtifactSelectors()\",\"{}.targetArtifacts()\",\"{}.targetSelectors()\",\"{}.excludeArtifacts()\",\"{}.failed()\",\"{}.excludeContracts()\",\"{}.IS_TEST()\"]'.format(
            contract, contract, contract, contract, contract, contract, contract, contract, contract, contract, contract, contract) + '\' >> config.yaml')
        tool_cmd += "echidna . --contract {} --config config.yaml".format(
            contract)
    elif tool == 'medusa':
        tool_cmd += "medusa fuzz --target-contracts {}".format(contract)
    else:
        raise ValueError('Unknown tool: {}'.format(tool))

    if preprocess != '':
        cmd(preprocess)
    cmd(quote(mutant_cmd))
    start_time = timer()
    status, stdout, stderr = cmd(split(quote(tool_cmd)))
    end_time = timer()
    with open(output_filename) as f:
        output = f.read()
        f.close()
    result = {
        'job_id': job_id,
        'tool': tool,
        'project': project,
        'contract': contract,
        'test': test,
        'mutant': mutant,
        'time': end_time - start_time,
        'status': status,
        'output': output,
        'stdout': stdout,
        'stderr': stderr,
    }
    cmd('git apply -R {}.patch'.format(tool))
    put_object('{}.json'.format(job_id), json.dumps(result), local)


def get_contract(test: str) -> str:
    status, stdout, stderr = cmd(
        "grep -r -l {} test | sed 's/.*\/\(.*\)\.t\.sol/\\1/g'".format(quote(test)))
    return stdout


def get_functions() -> List[str]:
    status, stdout, stderr = cmd(
        "grep -ro 'test_[a-zA-Z0-9_]*' test | sed 's/.*://g'")
    return stdout.split('\n')
