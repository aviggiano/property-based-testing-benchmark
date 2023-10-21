// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64Exp_2Properties is ABDKMath64x64Setup {
    // pow(2, x) == exp_2(x)
    function test_exp_2_equivalence_pow(uint256 x) public {
        try abdk.pow(TWO_FP, x) returns (int128 pow_2_x) {
            try abdk.fromUInt(x) returns (int128 x_fp) {
                try abdk.exp_2(x_fp) returns (int128 exp_2_x) {
                    assertEq(exp_2_x, pow_2_x);
                } catch {}
            } catch {}
        } catch {}
    }

    // if y = log_2(x) then exp_2(y) == x
    function test_exp_2_inverse(int128 x) public {
        try abdk.log_2(x) returns (int128 log_2_x) {
            try abdk.exp_2(log_2_x) returns (int128 exp_2_x) {
                uint256 bits = 50;

                if (log_2_x < ZERO_FP) {
                    bits = uint256(int256(bits) + int256(log_2_x));
                }

                try
                    abdk.equal_most_significant_bits_within_precision(
                        x,
                        exp_2_x,
                        bits
                    )
                returns (bool equal) {
                    assertTrue(equal);
                } catch {}
            } catch {}
        } catch {}
    }

    // exp_2(-x) == inv( exp_2(x) )
    function test_exp_2_negative_exponent(int128 x) public {
        x = int128(between(x, MIN_64x64 + 1, ZERO_FP - 1));

        try abdk.exp_2(x) returns (int128 exp_2_x) {
            try abdk.exp_2(-x) returns (int128 exp_2_minus_x) {
                try abdk.inv(exp_2_minus_x) returns (int128 inv_exp_2_minus_x) {
                    // Result should be within 4 bits precision for the worst case
                    try
                        abdk.equal_most_significant_bits_within_precision(
                            exp_2_x,
                            inv_exp_2_minus_x,
                            4
                        )
                    returns (bool equal) {
                        assertTrue(equal);
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // exp_2(0) == 1
    function test_exp_2_zero() public {
        int128 exp_zero = abdk.exp_2(ZERO_FP);
        assertEq(exp_zero, ONE_FP);
    }

    // exp_2(MAX) overflows
    function test_exp_2_maximum() public {
        try abdk.exp_2(MAX_64x64) {
            // Unexpected, should revert
            assertTrue(false);
        } catch {
            // Expected revert
        }
    }

    // 2 ** -x == 1 / 2 ** x that tends to zero as x increases
    function test_exp_2_minimum() public {
        try abdk.exp_2(MIN_64x64) returns (int128 result) {
            assertEq(result, ZERO_FP);
        } catch {
            // Unexpected revert
            assertTrue(false);
        }
    }
}
