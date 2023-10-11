default: help

PROTOCOLS = $(wildcard protocols/*)


help:
	@echo "usage:"
	@echo "	make halmos					use halmos"
	@echo "	make foundry					use foundry"

halmos:
	for protocol in $(PROTOCOLS); do \
		cd $$protocol; \
		git apply test/halmos/halmos.patch; \
		halmos --solver-subprocess --contract HalmosUniswapV2Properties --function test_ --print-potential-counterexample --solver-timeout-assertion 0; \
		git apply -R test/halmos/halmos.patch; \
	done

foundry:
	for protocol in $(PROTOCOLS); do \
		cd $$protocol; \
		forge test --match-path test/foundry/FoundryUniswapV2Properties.t.sol; \
	done