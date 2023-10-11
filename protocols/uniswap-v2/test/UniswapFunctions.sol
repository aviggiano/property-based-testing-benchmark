pragma solidity 0.8.17;

import "@uniswap/UniswapV2Pair.sol";
import "@crytic/properties/contracts/util/Hevm.sol";

import "./Setup.sol";
import "./Asserts.sol";

abstract contract UniswapFunctions is Setup, Asserts {
    function _provideInitialLiquidity(
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256, uint256) {
        amount0 = between(
            amount0,
            pair.MINIMUM_LIQUIDITY() + 1,
            token0.balanceOf(user)
        );
        amount1 = between(
            amount1,
            pair.MINIMUM_LIQUIDITY() + 1,
            token1.balanceOf(user)
        );

        return _provideLiquidity(amount0, amount1);
    }

    function _provideLiquidity(
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256, uint256) {
        amount0 = between(amount0, 0, token0.balanceOf(user));
        amount1 = between(amount1, 0, token1.balanceOf(user));

        hevm.prank(user);
        token0.transfer(address(pair), amount0);

        hevm.prank(user);
        token1.transfer(address(pair), amount1);

        hevm.prank(user);
        try pair.mint(user) {} catch {
            precondition(false);
        }

        return (amount0, amount1);
    }

    function _burnLiquidity(uint256 amount) internal returns (uint256) {
        precondition(pair.balanceOf(user) >= 1);
        amount = between(amount, 1, pair.balanceOf(user));

        hevm.prank(user);
        pair.transfer(address(pair), amount);

        hevm.prank(user);
        try pair.burn(user) {} catch {
            precondition(false);
        }

        return amount;
    }

    function _swap(
        bool zeroForOne,
        uint256 amount0,
        uint256 amount1,
        bool exact
    ) internal returns (uint256) {
        uint256 balance0Before = token0.balanceOf(user);
        uint256 balance1Before = token1.balanceOf(user);

        (uint256 reserve0Before, uint256 reserve1Before, ) = pair.getReserves();
        uint256 amount0In = amount0;
        uint256 amount1In = amount1;

        if (!exact) {
            amount0In = between(amount0, 1, balance0Before);
            amount1In = between(amount1, 1, balance1Before);
        }

        uint256 amount0Out;
        uint256 amount1Out;

        /**
         * Precondition of UniswapV2Pair.swap is that we transfer the token we are swapping in first.
         * So, we pick the larger of the two input amounts to transfer, and also use
         * the Uniswap library to determine how much of the other we will receive in return.
         */
        if (zeroForOne) {
            amount1In = 0;
            amount1Out = UniswapV2Library.getAmountOut(
                amount0In,
                reserve0Before,
                reserve1Before
            );
            precondition(amount1Out > 0);

            hevm.prank(user);
            token0.transfer(address(pair), amount0In);
        } else {
            amount0In = 0;
            amount0Out = UniswapV2Library.getAmountOut(
                amount1In,
                reserve1Before,
                reserve0Before
            );
            precondition(amount0Out > 0);

            hevm.prank(user);
            token1.transfer(address(pair), amount1In);
        }

        hevm.prank(user);
        pair.swap(amount0Out, amount1Out, address(user), "");
        return zeroForOne ? amount1Out : amount0Out;
    }

    function _getTokenPrice(
        bool zeroForOne,
        uint256 inputAmount
    ) internal view returns (uint256 amountOut) {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        amountOut = UniswapV2Library.getAmountOut(
            inputAmount,
            zeroForOne ? reserve0 : reserve1,
            zeroForOne ? reserve1 : reserve0
        );
    }
}
