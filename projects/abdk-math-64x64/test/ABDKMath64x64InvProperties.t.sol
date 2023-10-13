// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64ConversionProperties is ABDKMath64x64Setup {
    // 1 / (1 / x) == x
    function test_inv_double_inverse(int128 x) public {
        vm.assume(x != ZERO_FP);

        try abdk.inv(x) returns (int128 inv_x) {
            try abdk.inv(inv_x) returns (int128 double_inv_x) {
                try abdk.log_2(x) returns (int128 log_2_x) {
                    try abdk.toUInt(log_2_x) returns (uint64 log_2_x_uint) {
                        // The maximum loss of precision will be 2 * log2(x) bits rounded up
                        uint256 loss = 2 * log_2_x_uint + 2;

                        assertTrue(
                            abdk.equal_within_precision(x, double_inv_x, loss)
                        );
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // 1 / x == 1 / x
    function test_inv_division(int128 x) public {
        vm.assume(x != ZERO_FP);

        try abdk.inv(x) returns (int128 inv_x) {
            try abdk.div(ONE_FP, x) returns (int128 div_1_x) {
                assertEq(inv_x, div_1_x);
            } catch {}
        } catch {}
    }

    // x / y == 1 / (y / x)
    function test_inv_division_noncommutativity(int128 x, int128 y) public {
        vm.assume(x != ZERO_FP && y != ZERO_FP);

        try abdk.div(x, y) returns (int128 x_y) {
            try abdk.div(y, x) returns (int128 y_x) {
                try abdk.inv(y_x) returns (int128 inv_y_x) {
                    try abdk.inv(x) returns (int128 inv_x) {
                        try abdk.inv(y) returns (int128 inv_y) {
                            try
                                abdk.significant_bits_after_mul(x, inv_y)
                            returns (uint256 s__x__inv_y) {
                                try
                                    abdk.significant_bits_after_mul(y, inv_x)
                                returns (uint256 s__y__inv_x) {
                                    vm.assume(
                                        s__x__inv_y > REQUIRED_SIGNIFICANT_BITS
                                    );
                                    vm.assume(
                                        s__y__inv_x > REQUIRED_SIGNIFICANT_BITS
                                    );
                                    assertTrue(
                                        abdk.equal_within_tolerance(
                                            x_y,
                                            inv_y_x,
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

    // 1/(x * y) == 1/x * 1/y
    function test_inv_multiplication(int128 x, int128 y) public {
        vm.assume(x != ZERO_FP && y != ZERO_FP);

        try abdk.inv(x) returns (int128 inv_x) {
            try abdk.inv(y) returns (int128 inv_y) {
                try abdk.mul(inv_x, inv_y) returns (int128 inv_x_inv_y) {
                    try abdk.mul(x, y) returns (int128 x_y) {
                        try abdk.inv(x_y) returns (int128 inv_x_y) {
                            try
                                abdk.significant_bits_after_mul(inv_x, inv_y)
                            returns (uint256 s__inv_x__inv_y) {
                                try
                                    abdk.significant_bits_after_mul(x, y)
                                returns (uint256 s__x__y) {
                                    vm.assume(
                                        s__inv_x__inv_y >
                                            REQUIRED_SIGNIFICANT_BITS
                                    );
                                    vm.assume(
                                        s__x__y > REQUIRED_SIGNIFICANT_BITS
                                    );

                                    try abdk.log_2(x) returns (int128 log_2_x) {
                                        try abdk.log_2(y) returns (
                                            int128 log_2_y
                                        ) {
                                            // The maximum loss of precision is given by the formula:
                                            // 2 * | log_2(x) - log_2(y) | + 1
                                            uint256 loss = 2 *
                                                abdk.toUInt(
                                                    abdk.abs(log_2_x - log_2_y)
                                                ) +
                                                1;

                                            assertTrue(
                                                abdk.equal_within_precision(
                                                    inv_x_inv_y,
                                                    inv_x_y,
                                                    loss
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
        } catch {}
    }

    // (1 / x) * x == 1
    function test_inv_identity(int128 x) public {
        vm.assume(x != ZERO_FP);

        try abdk.inv(x) returns (int128 inv_x) {
            try abdk.mul(inv_x, x) returns (int128 identity) {
                try abdk.significant_bits_after_mul(inv_x, x) returns (
                    uint256 s__inv_x__x
                ) {
                    vm.assume(s__inv_x__x > REQUIRED_SIGNIFICANT_BITS);

                    // They should agree with a tolerance of one tenth of a percent
                    assertTrue(
                        abdk.equal_within_tolerance(
                            identity,
                            ONE_FP,
                            ONE_TENTH_FP
                        )
                    );
                } catch {}
            } catch {}
        } catch {}
    }

    // | 1 / x | <= 1 <=> |x| >= 1; | 1 / x | > 1 <=> |x| < 1
    function test_inv_values(int128 x) public {
        vm.assume(x != ZERO_FP);

        try abdk.inv(x) returns (int128 inv_x) {
            try abdk.abs(inv_x) returns (int128 abs_inv_x) {
                try abdk.abs(x) returns (int128 abs_x) {
                    if (abs_x >= ONE_FP) {
                        assertLe(abs_inv_x, ONE_FP);
                    } else {
                        assertGt(abs_inv_x, ONE_FP);
                    }
                } catch {}
            } catch {}
        } catch {}
    }

    // Test that the result has the same sign as the argument
    // 1 / x > 0 <=> x > 0; 1 / x < 0 <=> x < 0
    function test_inv_sign(int128 x) public {
        vm.assume(x != ZERO_FP);

        try abdk.inv(x) returns (int128 inv_x) {
            if (x > ZERO_FP) {
                assertGt(inv_x, ZERO_FP);
            } else {
                assertLt(inv_x, ZERO_FP);
            }
        } catch {}
    }
}
