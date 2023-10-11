pragma solidity 0.8.17;

import "@uniswap/UniswapV2Pair.sol";

import "forge-std/Test.sol";
import "./Setup.sol";
import "./Asserts.sol";
import "./UniswapFunctions.sol";

// References:
// https://github.com/crytic/properties/blob/548c494f8aac0771eb543b75a45369203f57407c/contracts/AMM/UniswapV2/UniswapV2PropertyTests.sol
abstract contract UniswapV2Properties is Test, UniswapFunctions {
    function setUp() public {
        _setup();
    }

    function test_provide_liquidity_increases_k(
        uint256 amount0,
        uint256 amount1
    ) public {
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        uint kBefore = reserve0Before * reserve1Before;

        (amount0, amount1) = _provideLiquidity(amount0, amount1);

        (uint reserve0After, uint reserve1After, ) = pair.getReserves();
        uint kAfter = reserve0After * reserve1After;
        lt(kBefore, kAfter, "Provide liquidity should increase k");
    }

    function test_provide_liquidity_increases_lp_total_supply(
        uint256 amount0,
        uint256 amount1
    ) public {
        uint256 lpTokenSupplyBefore = pair.totalSupply();

        (amount0, amount1) = _provideLiquidity(amount0, amount1);

        uint256 lpTokenSupplyAfter = pair.totalSupply();

        lt(
            lpTokenSupplyBefore,
            lpTokenSupplyAfter,
            "Provide liquidity should increase LP total supply"
        );
    }

    function test_provide_liquidity_does_not_change_token_price(
        uint256 amount0,
        uint256 amount1,
        bool zeroForOne,
        uint256 amountIn
    ) public {
        UniswapV2ERC20 inToken = zeroForOne ? token0 : token1;
        uint256 actualAmountIn = between(
            amountIn,
            1,
            inToken.balanceOf(address(user))
        );
        uint256 amountOutBefore = _getTokenPrice(zeroForOne, actualAmountIn);

        (amount0, amount1) = _provideLiquidity(amount0, amount1);

        uint256 amountOutAfter = _getTokenPrice(zeroForOne, actualAmountIn);

        eq(
            amountOutBefore,
            amountOutAfter,
            "Provide liquidity should not change token price"
        );
    }

    function test_provide_liquidity_increases_reserves(
        uint256 amount0,
        uint256 amount1
    ) public {
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();

        (amount0, amount1) = _provideLiquidity(amount0, amount1);

        (uint reserve0After, uint reserve1After, ) = pair.getReserves();

        lt(
            reserve0Before,
            reserve0After,
            "Provide liquidity should increase reserves"
        );
        lt(
            reserve1Before,
            reserve1After,
            "Provide liquidity should increase reserves"
        );
    }

    function test_provide_liquidity_increases_user_lp_balance(
        uint256 amount0,
        uint256 amount1
    ) public {
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));

        (amount0, amount1) = _provideLiquidity(amount0, amount1);

        uint lpTokenBalanceAfter = pair.balanceOf(address(user));

        lt(
            lpTokenBalanceBefore,
            lpTokenBalanceAfter,
            "Provide liquidity should increase user LP balance"
        );
    }

    function test_remove_liquidity_decreases_k(uint256 amount) public {
        pair.sync();

        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        uint kBefore = reserve0Before * reserve1Before;

        amount = _burnLiquidity(amount, lpTokenBalanceBefore);

        (uint reserve0After, uint reserve1After, ) = pair.getReserves();
        uint kAfter = reserve0After * reserve1After;
        gt(kBefore, kAfter, "Remove liquidity should decrease k");
    }

    function test_remove_liquidity_decreases_lp_total_supply(
        uint256 amount
    ) public {
        pair.sync();
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        uint256 supplyBefore = pair.totalSupply();

        amount = _burnLiquidity(amount, lpTokenBalanceBefore);

        uint256 supplyAfter = pair.totalSupply();

        lt(
            supplyAfter,
            supplyBefore,
            "Remove liquidity should decrease LP total supply"
        );
    }

    function test_remove_liquidity_does_not_change_token_price(
        uint256 amount,
        bool zeroForOne,
        uint256 amountIn
    ) public {
        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        UniswapV2ERC20 inToken = zeroForOne ? token0 : token1;
        uint256 actualAmountIn = between(
            amountIn,
            1,
            inToken.balanceOf(address(user))
        );
        uint256 amountOutBefore = _getTokenPrice(zeroForOne, actualAmountIn);

        // Burn liquidity
        amount = _burnLiquidity(amount, lpTokenBalanceBefore);

        uint256 amountOutAfter = _getTokenPrice(zeroForOne, actualAmountIn);

        eq(
            amountOutBefore,
            amountOutAfter,
            "Remove liquidity should not change token price"
        );
    }

    function test_remove_liquidity_decreases_reserves(uint256 amount) public {
        pair.sync();

        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();

        amount = _burnLiquidity(amount, lpTokenBalanceBefore);

        (uint reserve0After, uint reserve1After, ) = pair.getReserves();
        gt(
            reserve0Before,
            reserve0After,
            "Remove liquidity should decrease reserves"
        );
        gt(
            reserve1Before,
            reserve1After,
            "Remove liquidity should decrease reserves"
        );
    }

    function test_remove_liquidity_decreases_user_lp_balance(
        uint256 amount
    ) public {
        pair.sync();

        uint lpTokenBalanceBefore = pair.balanceOf(address(user));
        require(lpTokenBalanceBefore > 0);

        amount = _burnLiquidity(amount, lpTokenBalanceBefore);

        uint lpTokenBalanceAfter = pair.balanceOf(address(user));

        gt(
            lpTokenBalanceBefore,
            lpTokenBalanceAfter,
            "Remove liquidity should decrease user LP balance"
        );
    }

    // Swapping
    function test_swap_does_not_decrease_k(
        bool zeroForOne,
        uint256 amount0,
        uint256 amount1
    ) public {
        pair.skim(address(this));

        require(zeroForOne ? amount0 > 0 : amount1 > 0);
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);
        uint kBefore = reserve0Before * reserve1Before;

        _swap(zeroForOne, amount0, amount1, false);

        (uint reserve0After, uint reserve1After, ) = pair.getReserves();
        uint kAfter = reserve0After * reserve1After;
        gte(kAfter, kBefore, "Swap should not decrease k");
    }

    function test_swap_two_way_does_not_result_in_profit(
        bool zeroForOne,
        uint256 amountIn
    ) public {
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        uint256 balanceBefore0 = token0.balanceOf(address(user));
        uint256 balanceBefore1 = token1.balanceOf(address(user));

        uint256 amountOut = _swap(zeroForOne, amountIn, amountIn, false);
        _swap(!zeroForOne, amountOut, amountOut, true);

        uint256 balanceAfter0 = token0.balanceOf(address(user));
        uint256 balanceAfter1 = token1.balanceOf(address(user));

        lte(
            balanceAfter0,
            balanceBefore0,
            "Swap two way should not result in profit"
        );
        lte(
            balanceAfter1,
            balanceBefore1,
            "Swap two way should not result in profit"
        );
    }

    function test_swap_increases_user_out_balance(
        bool zeroForOne,
        uint256 amount0,
        uint256 amount1
    ) public {
        pair.skim(address(this));
        UniswapV2ERC20 outToken = zeroForOne ? token1 : token0;
        uint256 outBalanceBefore = outToken.balanceOf(address(user));

        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        _swap(zeroForOne, amount0, amount1, false);

        uint256 outBalanceAfter = outToken.balanceOf(address(user));

        gt(
            outBalanceAfter,
            outBalanceBefore,
            "Swap should increase user out balance"
        );
    }

    function test_swap_out_price_increases_in_price_decreases(
        bool zeroForOne,
        uint256 amountIn
    ) public {
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves();
        require(reserve0Before > 0 && reserve1Before > 0);

        UniswapV2ERC20 inToken = zeroForOne ? token0 : token1;
        UniswapV2ERC20 outToken = zeroForOne ? token1 : token0;

        uint256 actualAmountIn0 = between(
            amountIn,
            1,
            inToken.balanceOf(address(user))
        );
        uint256 actualAmountIn1 = between(
            amountIn,
            1,
            outToken.balanceOf(address(user))
        );
        uint256 amountOut1Before = _getTokenPrice(zeroForOne, actualAmountIn0);
        uint256 amountOut0Before = _getTokenPrice(!zeroForOne, actualAmountIn1);

        _swap(zeroForOne, amountIn, amountIn, false);

        uint256 amountOut1After = _getTokenPrice(zeroForOne, actualAmountIn0);
        uint256 amountOut0After = _getTokenPrice(!zeroForOne, actualAmountIn1);

        gt(amountOut1Before, amountOut1After, "Swap should increase out price");
        lt(amountOut0Before, amountOut0After, "Swap should decrease in price");
    }
}
