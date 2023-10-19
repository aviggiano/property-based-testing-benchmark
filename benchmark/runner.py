import tempfile
import os
import logging
from .exec import cmd
from shlex import quote, split

def run_benchmark(tool: str, project: str, test: str, mutant: str):
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
