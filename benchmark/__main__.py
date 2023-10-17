#!/usr/bin/env python3

import logging
from .log import mk_log
from .parser import mk_arg_parser
from .tools import exec


def main():
    parser = mk_arg_parser()
    args = parser.parse_args()
    mk_log()
    logging.info(vars(args))

    exec(args.tool, args.project, args.test, args.mutant)


if __name__ == "__main__":
    main()
