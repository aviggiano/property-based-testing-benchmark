// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64MulProperties is ABDKMath64x64Setup {
    // x * y == y * x
    function test_mul_commutative(int128 x, int128 y) public {
        try abdk.mul(x, y) returns (int128 x_y) {
            try abdk.mul(y, x) returns (int128 y_x) {
                assertEq(x_y, y_x);
            } catch {}
        } catch {}
    }

    // (x * y) * z == x * (y * z)
    function test_mul_associative(int128 x, int128 y, int128 z) public {
        try abdk.significant_bits_after_mul(x, y) returns (uint256 s__x__y) {
            vm.assume(s__x__y > REQUIRED_SIGNIFICANT_BITS);
            try abdk.significant_bits_after_mul(y, z) returns (
                uint256 s__y__z
            ) {
                vm.assume(s__y__z > REQUIRED_SIGNIFICANT_BITS);

                try abdk.mul(x, y) returns (int128 x_y) {
                    try abdk.significant_bits_after_mul(x_y, z) returns (
                        uint256 s__x_y__z
                    ) {
                        vm.assume(s__x_y__z > REQUIRED_SIGNIFICANT_BITS);

                        try abdk.mul(y, z) returns (int128 y_z) {
                            try
                                abdk.significant_bits_after_mul(x, y_z)
                            returns (uint256 s__x__y_z) {
                                vm.assume(
                                    s__x__y_z > REQUIRED_SIGNIFICANT_BITS
                                );

                                try abdk.mul(x_y, z) returns (int128 xy_z) {
                                    try abdk.mul(x, y_z) returns (int128 x_yz) {
                                        assertTrue(
                                            abdk.equal_within_tolerance(
                                                xy_z,
                                                x_yz,
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
        } catch {}
    }

    // x * (y + z) == x * y + x * z
    function test_mul_distributive(int128 x, int128 y, int128 z) public {
        try abdk.add(y, z) returns (int128 y_plus_z) {
            try abdk.significant_bits_after_mul(x, y_plus_z) returns (
                uint256 s__x__y_plus_z
            ) {
                vm.assume(s__x__y_plus_z > REQUIRED_SIGNIFICANT_BITS);
                try abdk.mul(x, y_plus_z) returns (int128 x_times_y_plus_z) {
                    try abdk.significant_bits_after_mul(x, y) returns (
                        uint256 s__x__y
                    ) {
                        vm.assume(s__x__y > REQUIRED_SIGNIFICANT_BITS);
                        try abdk.mul(x, y) returns (int128 x_times_y) {
                            try abdk.significant_bits_after_mul(x, z) returns (
                                uint256 s__x__z
                            ) {
                                vm.assume(s__x__z > REQUIRED_SIGNIFICANT_BITS);

                                try abdk.mul(x, z) returns (int128 x_times_z) {
                                    assertTrue(
                                        abdk.equal_within_tolerance(
                                            abdk.add(x_times_y, x_times_z),
                                            x_times_y_plus_z,
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

    // x * 1 == x
    // x * 0 == 0
    function test_mul_identity(int128 x) public {
        int128 x_1 = abdk.mul(x, ONE_FP);
        int128 x_0 = abdk.mul(x, ZERO_FP);

        assertEq(x_0, ZERO_FP);
        assertEq(x_1, x);
    }

    // x * y >= x <=> |y| >= 1; x * y < x <=> |y| < 1
    function test_mul_values(int128 x, int128 y) public {
        vm.assume(x != ZERO_FP && y != ZERO_FP);

        try abdk.mul(x, y) returns (int128 x_y) {
            try abdk.significant_digits_lost_in_mul(x, y) returns (
                bool s__x__y
            ) {
                vm.assume(!s__x__y);

                if (x >= ZERO_FP) {
                    if (y >= ONE_FP) {
                        assertGe(x_y, x);
                    } else {
                        assertLe(x_y, x);
                    }
                } else {
                    if (y >= ONE_FP) {
                        assertLe(x_y, x);
                    } else {
                        assertGe(x_y, x);
                    }
                }
            } catch {}
        } catch {}
    }

    // x * y <= MAX && x * y >= MIN
    function test_mul_range(int128 x, int128 y) public {
        int128 result;
        try abdk.mul(x, y) {
            result = abdk.mul(x, y);
            assertTrue(result <= MAX_64x64 && result >= MIN_64x64);
        } catch {
            // If it reverts, just ignore
        }
    }

    // MAX * 1 == MAX
    function test_mul_maximum_value() public {
        int128 result;
        try abdk.mul(MAX_64x64, ONE_FP) {
            // Expected behaviour, does not revert
            result = abdk.mul(MAX_64x64, ONE_FP);
            assertEq(result, MAX_64x64);
        } catch {
            assertTrue(false);
        }
    }

    // MIN * 1 == MIN
    function test_mul_minimum_value() public {
        int128 result;
        try abdk.mul(MIN_64x64, ONE_FP) {
            // Expected behaviour, does not revert
            result = abdk.mul(MIN_64x64, ONE_FP);
            assertEq(result, MIN_64x64);
        } catch {
            assertTrue(false);
        }
    }
}
