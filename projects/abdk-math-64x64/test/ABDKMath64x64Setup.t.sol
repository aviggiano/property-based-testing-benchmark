// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@abdk/ABDKMath64x64.sol";
import "./ABDKMath64x64Wrapper.sol";

// https://github.com/crytic/properties/blob/d573bf661990f11cc033e2b5b749deec962b5243/contracts/Math/ABDKMath64x64/ABDKMath64x64PropertyTests.sol
contract ABDKMath64x64Setup is Test {
    ABDKMath64x64Wrapper internal abdk;

    int128 internal ZERO_FP = ABDKMath64x64.fromInt(0);
    int128 internal ONE_FP = ABDKMath64x64.fromInt(1);
    int128 internal MINUS_ONE_FP = ABDKMath64x64.fromInt(-1);
    int128 internal TWO_FP = ABDKMath64x64.fromInt(2);
    int128 internal THREE_FP = ABDKMath64x64.fromInt(3);
    int128 internal EIGHT_FP = ABDKMath64x64.fromInt(8);
    int128 internal THOUSAND_FP = ABDKMath64x64.fromInt(1000);
    int128 internal MINUS_SIXTY_FOUR_FP = ABDKMath64x64.fromInt(-64);
    int128 internal EPSILON = 1;
    int128 internal ONE_TENTH_FP =
        ABDKMath64x64.div(ABDKMath64x64.fromInt(1), ABDKMath64x64.fromInt(10));

    uint256 internal REQUIRED_SIGNIFICANT_BITS = 10;

    int128 internal constant MIN_64x64 = -0x80000000000000000000000000000000;
    int128 internal constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256 internal constant MAX_256 =
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256 internal constant MIN_256 =
        -0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant MAX_U256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function setUp() public {
        abdk = new ABDKMath64x64Wrapper();
    }

    // These functions allows to compare a and b for equality, discarding
    // the last precision_bits bits.
    // An absolute value function is implemented inline in order to not use
    // the implementation from the library under test.
    function equal_within_precision(
        int128 a,
        int128 b,
        uint256 precision_bits
    ) internal pure returns (bool) {
        int128 max = (a > b) ? a : b;
        int128 min = (a > b) ? b : a;
        int128 r = (max - min) >> precision_bits;

        return (r == 0);
    }

    function equal_within_precision_u(
        uint256 a,
        uint256 b,
        uint256 precision_bits
    ) internal pure returns (bool) {
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
    ) internal view returns (bool) {
        int128 tol_value = abdk.abs(
            abdk.mul(a, abdk.div(error_percent, abdk.fromUInt(100)))
        );

        return (abdk.abs(abdk.sub(b, a)) <= tol_value);
    }

    // Return the i most significant bits from |n|. If n has less than i significant bits, return |n|
    // Uses functions from the library under test!
    function most_significant_bits(
        int128 n,
        uint256 i
    ) internal view returns (uint256) {
        // Create a mask consisting of i bits set to 1
        uint256 mask = (2 ** i) - 1;

        // Get the position of the MSB set to 1 of n
        uint256 pos = uint64(abdk.toInt(abdk.log_2(n)) + 64 + 1);

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
    ) internal view returns (bool) {
        // Get the number of bits in a and b
        // Since log(x) returns in the interval [-64, 63), add 64 to be in the interval [0, 127)
        uint256 a_bits = uint256(int256(abdk.toInt(abdk.log_2(a)) + 64));
        uint256 b_bits = uint256(int256(abdk.toInt(abdk.log_2(b)) + 64));

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
