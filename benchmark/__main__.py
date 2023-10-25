#!/usr/bin/env python3

import logging
from .log import mk_log
from .parser import mk_arg_parser
from .runner import run_benchmark
from .consumer import poll_messages
from .producer import send_message, full_benchmark


def main():
    parser = mk_arg_parser()
    args = parser.parse_args()
    mk_log()
    logging.info(vars(args))

    if args.cmd == 'producer':
        if args.full_benchmark:
            full_benchmark(args)
        else:
            send_message(args)

    if args.cmd == 'consumer':
        poll_messages(args)

    if args.cmd == 'runner':
        run_benchmark(args)


if __name__ == "__main__":
    main()
