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

    # analyser
    analyser = subparsers.add_parser(
        'analyser', help="Analyses benchmark results")
    analyser.set_defaults(cmd='analyser')

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

    consumer.add_argument(
        "--queue-statistics",
        action="store_true",
        help="print queue statistics",
    )

    # runner options

    runner.add_argument(
        "--preprocess",
        metavar="PRE",
        default="",
        help="preprocess command, e.g. apply a patch before running a specific tool (default: '%(default)s')",
    )
    runner.add_argument(
        "--postprocess",
        metavar="POST",
        default="",
        help="postprocess command, e.g. revert patch (default: '%(default)s')",
    )
    runner.add_argument(
        "--tool",
        metavar="TOOL",
        choices=["halmos", "foundry", "echidna", "medusa"],
        help="run benchmarks using one of the available tools",
    )
    runner.add_argument(
        "--project",
        metavar="PROJECT",
        choices=["abdk-math-64x64", "uniswap-v2", "dai-certora"],
        help="test against a specific project",
    )
    runner.add_argument(
        "--contract",
        metavar="CONTRACT",
        default="",
        help="run tests matching a given contract (default: '%(default)s')",
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
    runner.add_argument(
        "--prefix",
        metavar="PREFIX",
        default="",
        help="save output with a prefix (default: '%(default)s')",
    )
    runner.add_argument(
        "--extra-args",
        metavar="ARGS",
        default="",
        help="extra arguments for tool (default: '%(default)s')",
    )

    # analyser options

    analyser.add_argument(
        "--prefix",
        metavar="PREFIX",
        default="",
        help="load output with a prefix (default: '%(default)s')",
    )
    analyser.add_argument(
        "--load-from-csv",
        action="store_true",
        help="load output from CSV",
    )

    return parser
