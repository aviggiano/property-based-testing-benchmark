// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64ExpProperties is ABDKMath64x64Setup {
    // if y = ln(x) then exp(y) == x
    function test_exp_inverse(int128 x) public {
        try abdk.ln(x) returns (int128 ln_x) {
            try abdk.exp(ln_x) returns (int128 exp_x) {
                uint256 bits = 50;

                if (ln_x < ZERO_FP) {
                    bits = uint256(int256(bits) + int256(ln_x));
                }

                try
                    abdk.equal_most_significant_bits_within_precision(
                        x,
                        exp_x,
                        bits
                    )
                returns (bool equal) {
                    assertTrue(equal);
                } catch {}
            } catch {}
        } catch {}
    }

    // exp(-x) == inv( exp(x) )
    function test_exp_negative_exponent(int128 x) public {
        vm.assume(x < ZERO_FP && x != MIN_64x64);

        try abdk.exp(x) returns (int128 exp_x) {
            try abdk.exp(-x) returns (int128 exp_minus_x) {
                try abdk.inv(exp_minus_x) returns (int128 inv_exp_minus_x) {
                    // Result should be within 4 bits precision for the worst case
                    try
                        abdk.equal_most_significant_bits_within_precision(
                            exp_x,
                            inv_exp_minus_x,
                            4
                        )
                    returns (bool equal) {
                        assertTrue(equal);
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // exp(0) == 1
    function test_exp_zero() public {
        int128 exp_zero = abdk.exp(ZERO_FP);
        assertEq(exp_zero, ONE_FP);
    }

    // exp(MAX) reverts
    function test_exp_maximum() public {
        try abdk.exp(MAX_64x64) {
            // Unexpected, should revert
            assertTrue(false);
        } catch {
            // Expected revert
        }
    }

    // e ** -x == 1 / e ** x that tends to zero as x increases
    function test_exp_minimum() public {
        try abdk.exp(MIN_64x64) returns (int128 result) {
            // Expected, should not revert, check that value is zero
            assertEq(result, ZERO_FP);
        } catch {
            // Unexpected revert
            assertTrue(false);
        }
    }
}
