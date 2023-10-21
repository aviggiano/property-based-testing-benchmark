import os
import argparse
import json


def mk_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="benchmark", epilog="For more information, see https://github.com/aviggiano/property-based-testing-benchmark"
    )
    subparsers = parser.add_subparsers(
        help="Component (producer, consumer, runner)", required=True)

    # producer
    producer = subparsers.add_parser(
        'producer', help="Puts a benchmark job into the queue")
    producer.set_defaults(cmd='producer')

    # consumer
    consumer = subparsers.add_parser(
        'consumer', help="Polls benchmark jobs from the queue and spawns a runner")
    consumer.set_defaults(cmd='consumer')

    # runner
    runner = subparsers.add_parser(
        'runner', help="Runs a benchmark job and saves the output to the storage system")
    runner.set_defaults(cmd='runner')

    # generic options

    parser.add_argument(
        "--local",
        action="store_true",
        help="use local setup (in-memory queue, file system) instead of AWS components (SQS, S3)",
    )

    # producer options

    producer.add_argument(
        "--send-message",
        metavar="MSG",
        help="send message to queue",
        type=json.loads,
    )

    producer.add_argument(
        "--full-benchmark",
        action="store_true",
        help="start full benchmark against a specific project",
    )

    # consumer options

    consumer.add_argument(
        "--start-runner",
        metavar="MSG",
        help="hardcoded message from queue",
        type=json.loads,
    )

    # runner options

    runner.add_argument(
        "--tool",
        metavar="TOOL",
        choices=["halmos", "foundry", "echidna", "medusa"],
        help="run benchmarks using one of the available tools",
    )
    runner.add_argument(
        "--project",
        metavar="PROJECT",
        choices=["abdk-math-64x64", "uniswap-v2"],
        help="test against a specific project",
    )
    runner.add_argument(
        "--test",
        metavar="TEST",
        default="test_",
        help="run tests matching the given prefix only (default: '%(default)s')",
    )
    runner.add_argument(
        "--mutant",
        metavar="MUTANT",
        default="",
        help="test against mutated code containing injected bugs (default: '%(default)s')",
    )
    runner.add_argument(
        "--timeout",
        metavar="TIMEOUT",
        default=3600,
        help="run tests for a specific timeout (default: %(default)s)",
    )

    return parser
