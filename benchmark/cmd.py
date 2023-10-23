from typing import Tuple
import logging
from subprocess import PIPE, Popen


def cmd(cmd: str) -> Tuple[int, str, str]:
    logging.info(cmd)
    stdout = []
    stderr = []
    with Popen(cmd, stdout=PIPE, stderr=PIPE, bufsize=1, universal_newlines=True, shell=True) as p:
        for line in p.stdout:
            stdout.append(line)
            print(line, end='')
        for line in p.stderr:
            stderr.append(line)
            print(line, end='')

    status = p.returncode

    return status, ''.join(stdout)[:-1], ''.join(stderr)[:-1]
