pragma solidity ^0.8.0;

import "@uniswap/UniswapV2Pair.sol";
import "@uniswap/UniswapV2ERC20.sol";
import "@uniswap/UniswapV2Factory.sol";
import "@uniswap/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/contracts/UniswapV2Router01.sol";
import "@crytic/properties/contracts/util/Hevm.sol";

contract Setup {
    UniswapV2ERC20 internal token0;
    UniswapV2ERC20 internal token1;
    UniswapV2Pair internal pair;
    UniswapV2Factory internal factory;
    UniswapV2Router01 internal router;

    address internal user;

    function _setup() internal {
        user = address(0x123);
        token0 = new UniswapV2ERC20();
        token1 = new UniswapV2ERC20();
        factory = new UniswapV2Factory(address(this));
        factory.setFeeTo(address(this));
        router = new UniswapV2Router01(address(factory), address(0));
        pair = UniswapV2Pair(
            factory.createPair(address(token0), address(token1))
        );
        (address testTokenA, address testTokenB) = UniswapV2Library.sortTokens(
            address(token0),
            address(token1)
        );
        token0 = UniswapV2ERC20(testTokenA);
        token1 = UniswapV2ERC20(testTokenB);
    }

    function _mintTokens(uint256 amount1, uint256 amount2) internal {
        token1.mint(address(user), amount2);
        token0.mint(address(user), amount1);

        hevm.prank(user);
        token0.approve(address(router), type(uint256).max);

        hevm.prank(user);
        token1.approve(address(router), type(uint256).max);
    }
}
