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

    // These functions allows to compare a and b for equality, discarding
    // the last precision_bits bits.
    // An absolute value function is implemented inline in order to not use
    // the implementation from the library under test.
    function equal_within_precision(
        int128 a,
        int128 b,
        uint256 precision_bits
    ) public pure returns (bool) {
        int128 max = (a > b) ? a : b;
        int128 min = (a > b) ? b : a;
        int128 r = (max - min) >> precision_bits;

        return (r == 0);
    }

    function equal_within_precision_u(
        uint256 a,
        uint256 b,
        uint256 precision_bits
    ) public pure returns (bool) {
        uint256 max = (a > b) ? a : b;
        uint256 min = (a > b) ? b : a;
        uint256 r = (max - min) >> precision_bits;

        return (r == 0);
    }

    // This function determines if the relative error between a and b is less
    // than error_percent % (expressed as a 64x64 value)
    // Uses functions from the library under test!
    function equal_within_tolerance(
        int128 a,
        int128 b,
        int128 error_percent
    ) public pure returns (bool) {
        int128 tol_value = abs(mul(a, div(error_percent, fromUInt(100))));

        return (abs(sub(b, a)) <= tol_value);
    }

    // Return the i most significant bits from |n|. If n has less than i significant bits, return |n|
    // Uses functions from the library under test!
    function most_significant_bits(
        int128 n,
        uint256 i
    ) internal pure returns (uint256) {
        // Create a mask consisting of i bits set to 1
        uint256 mask = (2 ** i) - 1;

        // Get the position of the MSB set to 1 of n
        uint256 pos = uint64(toInt(log_2(n)) + 64 + 1);

        // Get the positive value of n
        uint256 value = (n > 0) ? uint128(n) : uint128(-n);

        // Shift the mask to match the rightmost 1-set bit
        if (pos > i) {
            mask <<= (pos - i);
        }

        return (value & mask);
    }

    // Returns true if the n most significant bits of a and b are almost equal
    // Uses functions from the library under test!
    function equal_most_significant_bits_within_precision(
        int128 a,
        int128 b,
        uint256 bits
    ) internal pure returns (bool) {
        // Get the number of bits in a and b
        // Since log(x) returns in the interval [-64, 63), add 64 to be in the interval [0, 127)
        uint256 a_bits = uint256(int256(toInt(log_2(a)) + 64));
        uint256 b_bits = uint256(int256(toInt(log_2(b)) + 64));

        // a and b lengths may differ in 1 bit, so the shift should take into account the longest
        uint256 shift_bits = (a_bits > b_bits)
            ? (a_bits - bits)
            : (b_bits - bits);

        // Get the _bits_ most significant bits of a and b
        uint256 a_msb = most_significant_bits(a, bits) >> shift_bits;
        uint256 b_msb = most_significant_bits(b, bits) >> shift_bits;

        // See if they are equal within 1 bit precision
        // This could be modified to get the precision as a parameter to the function
        return equal_within_precision_u(a_msb, b_msb, 1);
    }
}
