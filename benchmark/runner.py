from typing import List
import uuid
from os import chdir
import logging
import json
from .cmd import cmd
from .storage import put_object
from shlex import quote, split
from timeit import default_timer as timer


def run_benchmark(args: dict):
    job_id = str(uuid.uuid4())
    logging.info('Running benchmark {}'.format(job_id))

    chdir('projects/{}'.format(quote(args.project)))

    # FIXME use filterFunctions
    # for fun in get_functions():
    #     if fun.startswith(args.test) == False:
    #         # https://stackoverflow.com/questions/5694228/sed-in-place-flag-that-works-both-on-mac-bsd-and-linux
    #         # NOTE: this only works on GNU sed
    #         cmd("find test -type f -exec sed -i -e 's/\(" +
    #             fun + "\\b.*\)public/\\1private/' \{\} \;")

    output_filename = '{}-output.json'.format(job_id)
    output = ''
    with open(output_filename, 'a+') as f:
        f.close()

    tool_cmd = 'timeout -k 10 {} {}'.format(args.timeout, args.extra_args)

    if args.preprocess != '':
        cmd(args.preprocess)
    start_time = timer()
    status, stdout, stderr = cmd(split(quote(tool_cmd)))
    end_time = timer()
    with open(output_filename) as f:
        output = f.read()
        f.close()
    result = {
        'job_id': job_id,
        'tool': args.tool,
        'project': args.project,
        'test': args.test,
        'preprocess': args.preprocess,
        'postprocess': args.postprocess,
        'extra_args': args.extra_args,
        'tool_cmd': tool_cmd,
        'mutant': args.mutant,
        'time': end_time - start_time,
        'status': status,
        'output': output,
        'stdout': stdout,
        'stderr': stderr,
    }
    if args.postprocess != '':
        cmd(args.postprocess)
    put_object('{}{}.json'.format(args.prefix, job_id),
               json.dumps(result), args.local)
    logging.info("Done")


def get_contract(test: str) -> str:
    logging.info('Getting contract for test {}'.format(test))
    status, stdout, stderr = cmd(
        "grep -r -l {} test | sed 's/.*\/\(.*\)\.t\.sol/\\1/g'".format(quote(test)))
    return stdout


def get_functions() -> List[str]:
    logging.info('Getting functions')
    status, stdout, stderr = cmd(
        "grep -ro 'test_[a-zA-Z0-9_]*' test | sed 's/.*://g'")
    return stdout.split('\n')
