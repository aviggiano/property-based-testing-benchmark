#!/usr/bin/env python3

import logging
from .log import mk_log
from .parser import mk_arg_parser
from .tools import exec
from .consumer import mk_consumer
from .producer import send_message

def main():
    parser = mk_arg_parser()
    args = parser.parse_args()
    mk_log()
    logging.info(vars(args))

    consumer = mk_consumer(args.local)

    if args.send_message is not None:
        send_message(args.send_message, args.local)

    if args.exec is True:
        exec(args.tool, args.project, args.test, args.mutant)


if __name__ == "__main__":
    main()
