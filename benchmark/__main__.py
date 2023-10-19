#!/usr/bin/env python3

import logging
from .log import mk_log
from .parser import mk_arg_parser
from .tools import exec_benchmark
from .consumer import poll_messages
from .producer import send_message

def main():
    parser = mk_arg_parser()
    args = parser.parse_args()
    mk_log()
    logging.info(vars(args))

    if args.cmd == 'producer':
        send_message(args.send_message, args.local)

    if args.cmd == 'consumer':
        poll_messages(args.local)

    if args.cmd == 'runner':
        exec_benchmark(args.tool, args.project, args.test, args.mutant)


if __name__ == "__main__":
    main()
