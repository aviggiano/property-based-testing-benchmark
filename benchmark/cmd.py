from typing import Tuple
import logging
from subprocess import PIPE, Popen


def cmd(cmd: str) -> Tuple[int, str, str]:
    logging.info(cmd)
    status = ''
    stdout = ''
    stderr = ''
    with Popen(cmd, stdout=PIPE, stderr=PIPE, bufsize=1, universal_newlines=True, shell=True) as p:
        for line in p.stdout:
            stdout += line + '\n'
            print(line, end='')
        for line in p.stderr:
            stderr += line + '\n'
            print(line, end='')

    status = p.returncode

    return status, stdout, stderr
