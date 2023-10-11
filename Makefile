default: help

PROTOCOLS = $(wildcard protocols/*)


help:
	@echo "usage:"
	@echo "	make halmos					use halmos"
	@echo "	make foundry					use foundry"

halmos:
	for protocol in $(PROTOCOLS); do \
		cd $$protocol; \
		halmos --solver-subprocess --contract HalmosUniswapV2Properties --function test_ --print-potential-counterexample --solver-timeout-assertion 0; \
	done

foundry:
	for protocol in $(PROTOCOLS); do \
		cd $$protocol; \
		forge test --match-path test/foundry/FoundryUniswapV2Properties.t.sol; \
	done