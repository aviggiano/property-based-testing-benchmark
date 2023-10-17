import os
import argparse


def mk_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="benchmark", epilog="For more information, see https://github.com/aviggiano/property-based-testing-benchmark"
    )

    parser.add_argument(
        "--tool",
        metavar="TOOL",
        help="run benchmarks using one of the available tools: halmos, foundry, echidna, medusa",
        required=True,
    )
    parser.add_argument(
        "--project", 
        metavar="PROJECT", 
        help="test against a specific project: abdkmath-64x64, uniswap-v2",
        required=True,
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

    return parser