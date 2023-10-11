#!/usr/bin/env bash

set -ux

for PROTOCOL in $(ls protocols); do
	cd protocols/$PROTOCOL
	halmos --solver-subprocess --function test_ --print-potential-counterexample --solver-timeout-assertion 0
	cd -
done