// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@abdk/ABDKMath64x64.sol";

contract ABDKMath64x64Wrapper {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for int256;
    using ABDKMath64x64 for uint256;

    function fromInt(int256 x) public pure returns (int128) {
        return x.fromInt();
    }

    function toInt(int128 x) public pure returns (int64) {
        return x.toInt();
    }

    function fromUInt(uint256 x) public pure returns (int128) {
        return x.fromUInt();
    }

    function toUInt(int128 x) public pure returns (uint64) {
        return x.toUInt();
    }

    function add(int128 x, int128 y) public pure returns (int128) {
        return x.add(y);
    }

    function sub(int128 x, int128 y) public pure returns (int128) {
        return x.sub(y);
    }

    function mul(int128 x, int128 y) public pure returns (int128) {
        return x.mul(y);
    }

    function mulu(int128 x, uint256 y) public pure returns (uint256) {
        return x.mulu(y);
    }

    function div(int128 x, int128 y) public pure returns (int128) {
        return x.div(y);
    }

    function neg(int128 x) public pure returns (int128) {
        return x.neg();
    }

    function abs(int128 x) public pure returns (int128) {
        return x.abs();
    }

    function inv(int128 x) public pure returns (int128) {
        return x.inv();
    }

    function avg(int128 x, int128 y) public pure returns (int128) {
        return x.avg(y);
    }

    function gavg(int128 x, int128 y) public pure returns (int128) {
        return x.gavg(y);
    }

    function pow(int128 x, uint256 y) public pure returns (int128) {
        return x.pow(y);
    }

    function sqrt(int128 x) public pure returns (int128) {
        return x.sqrt();
    }

    function log_2(int128 x) public pure returns (int128) {
        return x.log_2();
    }

    function ln(int128 x) public pure returns (int128) {
        return x.ln();
    }

    function exp_2(int128 x) public pure returns (int128) {
        return x.exp_2();
    }

    function exp(int128 x) public pure returns (int128) {
        return x.exp();
    }

    // Return how many significant bits will remain after multiplying a and b
    // Uses functions from the library under test!
    function significant_bits_after_mul(
        int128 a,
        int128 b
    ) public pure returns (uint256) {
        int128 x = a >= 0 ? a : -a;
        int128 y = b >= 0 ? b : -b;

        int128 lx = x.log_2().toInt();
        int128 ly = y.log_2().toInt();
        int256 prec = lx + ly - 1;

        if (prec < -64) return 0;
        else return (64 + uint256(prec));
    }

    // Check that there are remaining significant digits after a multiplication
    // Uses functions from the library under test!
    function significant_digits_lost_in_mul(
        int128 a,
        int128 b
    ) public pure returns (bool) {
        int128 x = a >= 0 ? a : -a;
        int128 y = b >= 0 ? b : -b;

        int128 lx = x.log_2().toInt();
        int128 ly = y.log_2().toInt();

        return (lx + ly - 1 <= -64);
    }
}
