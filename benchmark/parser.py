import os
import argparse


def mk_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="benchmark", epilog="For more information, see https://github.com/aviggiano/property-based-testing-benchmark"
    )

    parser.add_argument(
        "--tool",
        metavar="TOOL",
        choices=["halmos", "foundry", "echidna", "medusa"],
        help="run benchmarks using one of the available tools",
    )
    parser.add_argument(
        "--project", 
        metavar="PROJECT", 
        choices=["abdk-math-64x64", "uniswap-v2"],
        help="test against a specific project",
    )
    parser.add_argument(
        "--test",
        metavar="TEST",
        default="test_",
        help="run tests matching the given prefix only (default: %(default)s)",
    )
    parser.add_argument(
        "--mutant",
        metavar="MUTANT",
        default="",
        help="test against mutated code containing injected bugs (default: %(default)s)",
    )
    parser.add_argument(
        "--local",
        action="store_true",
        help="use local setup (in-memory queue, file system) instead of AWS components (SQS, S3)",
    )
    parser.add_argument(
        "--exec",
        action="store_true",
        help="execute benchmark",
    )
    parser.add_argument(
        "--send-message",
        metavar="MESSAGE",
        help="send message to queue",
    )
    parser.add_argument(
        "--poll-messages",
        action="store_true",
        help="poll messages from queue",
    )

    return parser