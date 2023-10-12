pragma solidity ^0.8.0;

import "@uniswap/UniswapV2Pair.sol";
import "@uniswap/UniswapV2ERC20.sol";
import "@uniswap/UniswapV2Factory.sol";
import "@uniswap/contracts/libraries/UniswapV2Library.sol";
import "@crytic/properties/contracts/util/Hevm.sol";

contract Setup {
    UniswapV2ERC20 internal token0;
    UniswapV2ERC20 internal token1;
    UniswapV2Pair internal pair;
    UniswapV2Factory internal factory;

    address internal user;

    function _setup() internal {
        user = address(0x123456);
        token0 = new UniswapV2ERC20();
        token1 = new UniswapV2ERC20();
        factory = new UniswapV2Factory(address(this));
        // factory.setFeeTo(address(this));
        pair = UniswapV2Pair(
            factory.createPair(address(token0), address(token1))
        );
        (address testTokenA, address testTokenB) = UniswapV2Library.sortTokens(
            address(token0),
            address(token1)
        );
        token0 = UniswapV2ERC20(testTokenA);
        token1 = UniswapV2ERC20(testTokenB);

        token0.mint(user, type(uint64).max);
        token1.mint(user, type(uint64).max);
    }
}
