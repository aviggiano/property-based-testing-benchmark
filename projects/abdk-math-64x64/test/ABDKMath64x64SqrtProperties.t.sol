// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64SqrtProperties is ABDKMath64x64Setup {
    // sqrt(x) * sqrt(x) == x
    function test_sqrt_inverse_mul(int128 x) public {
        x = int128(between(x, ZERO_FP, type(int128).max));

        try abdk.sqrt(x) returns (int128 sqrt_x) {
            try abdk.mul(sqrt_x, sqrt_x) returns (int128 sqrt_x_mul_sqrt_x) {
                try abdk.log_2(x) returns (int128 log_2_x) {
                    try abdk.toUInt(log_2_x) returns (uint64 log_2_x_uint) {
                        // Precision loss is at most half the bits of the operand
                        try
                            abdk.equal_within_precision(
                                sqrt_x_mul_sqrt_x,
                                x,
                                (log_2_x_uint >> 1) + 2
                            )
                        returns (bool equal) {
                            assertTrue(equal);
                        } catch {}
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // sqrt(x) ** 2 == x
    function test_sqrt_inverse_pow(int128 x) public {
        x = int128(between(x, ZERO_FP, type(int128).max));

        try abdk.sqrt(x) returns (int128 sqrt_x) {
            try abdk.pow(sqrt_x, 2) returns (int128 sqrt_x_pow_2) {
                try abdk.log_2(x) returns (int128 log_2_x) {
                    try abdk.toUInt(log_2_x) returns (uint64 log_2_x_uint) {
                        // Precision loss is at most half the bits of the operand
                        try
                            abdk.equal_within_precision(
                                sqrt_x_pow_2,
                                x,
                                (log_2_x_uint >> 1) + 2
                            )
                        returns (bool equal) {
                            assertTrue(equal);
                        } catch {}
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // sqrt(x) * sqrt(y) == sqrt(x * y)
    function test_sqrt_distributive(int128 x, int128 y) public {
        x = int128(between(x, ZERO_FP, type(int128).max));
        y = int128(between(y, ZERO_FP, type(int128).max));

        // Ensure we have enough significant digits for the result to be meaningful
        try abdk.significant_bits_after_mul(x, y) returns (uint256 s__x__y) {
            precondition(s__x__y > REQUIRED_SIGNIFICANT_BITS);

            try abdk.sqrt(x) returns (int128 sqrt_x) {
                try abdk.sqrt(y) returns (int128 sqrt_y) {
                    try
                        abdk.significant_bits_after_mul(sqrt_x, sqrt_y)
                    returns (uint256 s__sqrt_x__sqrt_y) {
                        precondition(
                            s__sqrt_x__sqrt_y > REQUIRED_SIGNIFICANT_BITS
                        );

                        try abdk.mul(sqrt_x, sqrt_y) returns (
                            int128 sqrt_x_sqrt_y
                        ) {
                            try abdk.mul(x, y) returns (int128 x_mul_y) {
                                try abdk.sqrt(x_mul_y) returns (
                                    int128 sqrt_xy
                                ) {
                                    // Allow an error of up to one tenth of a percent
                                    assertTrue(
                                        abdk.equal_within_tolerance(
                                            sqrt_x_sqrt_y,
                                            sqrt_xy,
                                            ONE_TENTH_FP
                                        )
                                    );
                                } catch {}
                            } catch {}
                        } catch {}
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // sqrt(0) == 0
    function test_sqrt_zero() public {
        assertEq(abdk.sqrt(ZERO_FP), ZERO_FP);
    }

    // sqrt(MAX) does not revert
    function test_sqrt_maximum() public {
        try abdk.sqrt(MAX_64x64) {
            // Expected behaviour, MAX_64x64 is positive, and operation
            // should not revert as the result is in range
        } catch {
            // Unexpected, should not revert
            assertTrue(false);
        }
    }

    // sqrt(MAX) reverts
    function test_sqrt_minimum() public {
        try abdk.sqrt(MIN_64x64) {
            // Unexpected, should revert. MIN_64x64 is negative.
            assertTrue(false);
        } catch {
            // Expected behaviour, revert
        }
    }

    // sqrt(x) reverts if x < 0
    function test_sqrt_negative(int128 x) public {
        x = int128(between(x, type(int128).min, ZERO_FP - 1));

        try abdk.sqrt(x) {
            // Unexpected, should revert
            assertTrue(false);
        } catch {
            // Expected behaviour, revert
        }
    }
}
