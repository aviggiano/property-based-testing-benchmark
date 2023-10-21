// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64LnProperties is ABDKMath64x64Setup {
    // ln(x * y) = ln(x) + ln(y)
    function test_ln_distributive_mul(int128 x, int128 y) public {
        // Ensure we have enough significant digits for the result to be meaningful
        try abdk.significant_bits_after_mul(x, y) returns (uint256 s__x__y) {
            precondition(s__x__y > REQUIRED_SIGNIFICANT_BITS);
            try abdk.ln(x) returns (int128 ln_x) {
                try abdk.ln(y) returns (int128 ln_y) {
                    try abdk.mul(x, y) returns (int128 xy) {
                        try abdk.ln(xy) returns (int128 ln_xy) {
                            try abdk.add(ln_x, ln_y) returns (
                                int128 ln_x_ln_y
                            ) {
                                // The maximum loss of precision is given by the formula:
                                // | log_2(x) + log_2(y) |
                                uint256 loss = abdk.toUInt(
                                    abdk.log_2(x) + abdk.log_2(y)
                                );

                                try
                                    abdk.equal_within_precision(
                                        ln_xy,
                                        ln_x_ln_y,
                                        loss
                                    )
                                returns (bool equal) {
                                    assertTrue(equal);
                                } catch {}
                            } catch {}
                        } catch {}
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // Test for logarithm of a power
    // ln(x ** y) = y * ln(x)
    function test_ln_power(int128 x, uint256 y) public {
        try abdk.ln(x) returns (int128 ln_x) {
            try abdk.pow(x, y) returns (int128 x_y) {
                try abdk.ln(x_y) returns (int128 ln_x_y) {
                    try abdk.mulu(ln_x, y) returns (uint256 y_ln_x) {
                        assertEq(y_ln_x, abdk.toUInt(ln_x_y));
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // ln(0) reverts
    function test_ln_zero() public {
        try abdk.ln(ZERO_FP) {
            // Unexpected, should revert
            assertTrue(false);
        } catch {
            // Expected revert, ln(0) is not defined
        }
    }

    // ln(MAX) > 0
    function test_ln_maximum() public {
        try abdk.ln(MAX_64x64) returns (int128 result) {
            assertTrue(result > ZERO_FP);
        } catch {
            // Unexpected
            assertTrue(false);
        }
    }

    // ln(MIN) reverts
    function test_ln_negative(int128 x) public {
        precondition(x < ZERO_FP);

        try abdk.ln(x) {
            // Unexpected, should revert
            assertTrue(false);
        } catch {
            // Expected
        }
    }
}
