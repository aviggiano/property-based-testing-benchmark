import tempfile
import os
from subprocess import PIPE, Popen
import logging
from shlex import quote, split

def cmd(cmd: str):
    logging.info(cmd)
    with Popen(cmd, stdout=PIPE, bufsize=1, universal_newlines=True, shell=True) as p:
        for line in p.stdout:
            print(line, end='') # process line here

    if p.returncode != 0:
        raise CalledProcessError(p.returncode, p.args)



def exec(tool: str, project: str, test: str, mutant: str):
  mutant_cmd = 'true'
  if mutant != '':
    mutant_cmd = 'git apply mutants/{}.patch'.format(quote(mutant))
  tool_cmd = 'true'
  if tool == 'halmos':
    tool_cmd = "halmos --solver-subprocess --function {} --print-potential-counterexample".format(quote(test))
  elif tool == 'foundry':
    tool_cmd = "forge test --match-test {}".format(quote(test))
  else:
    raise ValueError('Unknown tool: {}'.format(tool))
  os.chdir('projects/{}'.format(quote(project)))
  cmd(quote(mutant_cmd))
  cmd(split(quote(tool_cmd)))
