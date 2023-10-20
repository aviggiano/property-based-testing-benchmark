import uuid
import os
import logging
import json
from .exec import cmd
from .storage import put_object
from shlex import quote, split
from timeit import default_timer as timer

TIMEOUT = 60 * 60

def run_benchmark(tool: str, project: str, test: str, mutant: str, local=False):
  mutant_cmd = 'true'
  if mutant != '':
    mutant_cmd = 'git apply mutants/{}.patch'.format(quote(mutant))
  tool_cmd = 'timeout -k 10 {} '.format(TIMEOUT)
  if tool == 'halmos':
    tool_cmd += "halmos --test-parallel --solver-subprocess --function {}".format(quote(test))
  elif tool == 'foundry':
    tool_cmd += "forge test --match-test {}".format(quote(test))
  else:
    raise ValueError('Unknown tool: {}'.format(tool))
  tool_cmd += ' >/dev/null'
  
  os.chdir('projects/{}'.format(quote(project)))
  cmd('forge clean')
  cmd(quote(mutant_cmd))
  start_time = timer()
  status = cmd(split(quote(tool_cmd)))
  end_time = timer()
  job_id = str(uuid.uuid4())
  result = {
    'job_id': job_id,
    'tool': tool,
    'project': project,
    'test': test,
    'mutant': mutant,
    'time': end_time - start_time,
    'status': status
  }
  put_object('{}.json'.format(job_id), json.dumps(result), local)