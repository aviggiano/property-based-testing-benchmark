// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64AbsProperties is ABDKMath64x64Setup {
    // |x| >= 0
    function test_abs_positive(int128 x) public {
        try abdk.abs(x) returns (int128 abs_x) {
            assertGe(abs_x, ZERO_FP);
        } catch {}
    }

    // |x| == |-x|
    function test_abs_negative(int128 x) public {
        try abdk.abs(x) returns (int128 abs_x) {
            int128 abs_minus_x = abdk.abs(abdk.neg(x));
            assertEq(abs_x, abs_minus_x);
        } catch {}
    }

    // | x * y | == |x| * |y|
    function test_abs_multiplicativeness(int128 x, int128 y) public {
        try abdk.abs(x) returns (int128 abs_x) {
            try abdk.abs(y) returns (int128 abs_y) {
                try abdk.mul(x, y) returns (int128 xy) {
                    try abdk.abs(xy) returns (int128 abs_xy) {
                        try abdk.mul(abs_x, abs_y) returns (
                            int128 abs_x_abs_y
                        ) {
                            try
                                abdk.significant_digits_lost_in_mul(
                                    abs_x,
                                    abs_y
                                )
                            returns (bool lost) {
                                // Failure if all significant digits are lost
                                vm.assume(!lost);

                                // Assume a tolerance of two bits of precision
                                assertTrue(
                                    abdk.equal_within_precision(
                                        abs_xy,
                                        abs_x_abs_y,
                                        2
                                    )
                                );
                            } catch {}
                        } catch {}
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // | x + y | <= |x| + |y|
    function test_abs_subadditivity(int128 x, int128 y) public {
        try abdk.abs(x) returns (int128 abs_x) {
            try abdk.abs(y) returns (int128 abs_y) {
                try abdk.add(x, y) returns (int128 x_y) {
                    try abdk.abs(x_y) returns (int128 abs_xy) {
                        try abdk.add(abs_x, abs_y) returns (
                            int128 abs_x_abs_y
                        ) {
                            assertLe(abs_xy, abs_x_abs_y);
                        } catch {}
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // | 0 | == 0
    function test_abs_zero() public {
        try abdk.abs(ZERO_FP) returns (int128 abs_zero) {
            // If it doesn't revert, the value must be zero
            abs_zero = abdk.abs(ZERO_FP);
            assertEq(abs_zero, ZERO_FP);
        } catch {
            // Unexpected, the function must not revert here
            assertTrue(false);
        }
    }

    // | MAX | == MAX
    function test_abs_maximum() public {
        int128 abs_max;

        try abdk.abs(MAX_64x64) {
            // If it doesn't revert, the value must be MAX_64x64
            abs_max = abdk.abs(MAX_64x64);
            assertEq(abs_max, MAX_64x64);
        } catch {}
    }

    // | MIN | == -MIN
    function test_abs_minimum() public {
        try abdk.abs(MIN_64x64) returns (int128 abs_min) {
            // If it doesn't revert, the value must be the negative of MIN_64x64
            abs_min = abdk.abs(MIN_64x64);
            assertEq(abs_min, abdk.neg(MIN_64x64));
        } catch {}
    }
}
