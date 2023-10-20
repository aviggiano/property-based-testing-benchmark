import logging
from subprocess import PIPE, Popen

def cmd(cmd: str) -> int:
    logging.info(cmd)
    with Popen(cmd, stdout=PIPE, bufsize=1, universal_newlines=True, shell=True) as p:
        for line in p.stdout:
            print(line, end='') # process line here

    return p.returncode


