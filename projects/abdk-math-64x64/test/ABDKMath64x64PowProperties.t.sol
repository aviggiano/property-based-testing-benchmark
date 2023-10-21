// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64PowProperties is ABDKMath64x64Setup {
    // x ** 0 == 1
    function test_pow_zero_exponent(int128 x) public {
        try abdk.pow(x, 0) returns (int128 x_pow_0) {
            assertEq(x_pow_0, ONE_FP);
        } catch {}
    }

    // 0 ** x == 0 if x > 0
    function test_pow_zero_base(uint256 x) public {
        precondition(x != 0);

        try abdk.pow(ZERO_FP, x) returns (int128 zero_pow_x) {
            assertEq(zero_pow_x, ZERO_FP);
        } catch {}
    }

    // x ** 1 == x
    function test_pow_one_exponent(int128 x) public {
        try abdk.pow(x, 1) returns (int128 x_pow_1) {
            assertEq(x_pow_1, x);
        } catch {}
    }

    // 1 ** x == 1
    function test_pow_base_one(uint256 x) public {
        try abdk.pow(ONE_FP, x) returns (int128 one_pow_x) {
            assertEq(one_pow_x, ONE_FP);
        } catch {}
    }

    // x ** a * x ** b == x ** (a + b)
    function test_pow_product_same_base(int128 x, uint256 a, uint256 b) public {
        precondition(x != ZERO_FP);
        a = between(a, 0, type(uint256).max - b);

        try abdk.pow(x, a) returns (int128 x_a) {
            try abdk.pow(x, b) returns (int128 x_b) {
                try abdk.pow(x, a + b) returns (int128 x_a_b) {
                    try abdk.mul(x_a, x_b) returns (int128 x_a_mul_x_b) {
                        try
                            abdk.equal_within_precision(x_a_mul_x_b, x_a_b, 2)
                        returns (bool equal) {
                            assertTrue(equal);
                        } catch {}
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // (x ** a) ** b == x ** (a * b)
    function test_pow_power_of_an_exponentiation(
        int128 x,
        uint256 a,
        uint256 b
    ) public {
        precondition(x != ZERO_FP);
        precondition(
            (a == 0 || b == 0) ||
                (a <= type(uint256).max / b && b <= type(uint256).max / a)
        );
        try abdk.pow(x, a) returns (int128 x_a) {
            try abdk.pow(x_a, b) returns (int128 x_a_b) {
                try abdk.pow(x, a * b) returns (int128 x_ab) {
                    try abdk.equal_within_precision(x_a_b, x_ab, 2) returns (
                        bool equal
                    ) {
                        assertTrue(equal);
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // (x * y) ** a == x ** a * y ** a
    function test_pow_distributive(int128 x, int128 y, uint256 a) public {
        precondition(x != ZERO_FP && y != ZERO_FP);
        a = between(a, 2 ** 32 + 1, type(uint256).max); // to avoid massive loss of precision

        try abdk.pow(x, a) returns (int128 x_a) {
            try abdk.pow(y, a) returns (int128 y_a) {
                try abdk.mul(x, y) returns (int128 x_mul_y) {
                    try abdk.pow(x_mul_y, a) returns (int128 x_mul_y_a) {
                        try abdk.mul(x_a, y_a) returns (int128 x_a_mul_y_a) {
                            try
                                abdk.equal_within_precision(
                                    x_mul_y_a,
                                    x_a_mul_y_a,
                                    2
                                )
                            returns (bool equal) {
                                assertTrue(equal);
                            } catch {}
                        } catch {}
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // | x ** a | >= 1 if | x | >= 1
    // | x ** a | <= 1 if | x | <= 1
    function test_pow_values(int128 x, uint256 a) public {
        precondition(x != ZERO_FP);

        try abdk.pow(x, a) returns (int128 x_a) {
            try abdk.abs(x) returns (int128 abs_x) {
                try abdk.abs(x_a) returns (int128 abs_x_a) {
                    if (abs_x >= ONE_FP) {
                        assertGe(abs_x_a, ONE_FP);
                    }

                    if (abs_x <= ONE_FP) {
                        assertLe(abs_x_a, ONE_FP);
                    }
                } catch {}
            } catch {}
        } catch {}
    }

    // x ** a == | x ** a | if | a | % 2 == 0
    // x ** a > 0 if | a | % 2 == 0
    // x ** a < 0 if | a | % 2 != 0
    function test_pow_sign(int128 x, uint256 a) public {
        precondition(x != ZERO_FP && a != 0);

        try abdk.pow(x, a) returns (int128 x_a) {
            // This prevents the case where a small negative number gets
            // rounded down to zero and thus changes sign
            precondition(x_a != ZERO_FP);
            try abdk.abs(x_a) returns (int128 abs_x_a) {
                // If the exponent is even
                if (a % 2 == 0) {
                    assertEq(x_a, abs_x_a);
                } else {
                    // x_a preserves x sign
                    if (x < ZERO_FP) {
                        assertLt(x_a, ZERO_FP);
                    } else {
                        assertGt(x_a, ZERO_FP);
                    }
                }
            } catch {}
        } catch {}
    }

    // MAX ** a reverts
    function test_pow_maximum_base(uint256 a) public {
        a = between(a, 2, type(uint256).max);

        try abdk.pow(MAX_64x64, a) {
            // Unexpected, should revert because of overflow
            assertTrue(false);
        } catch {
            // Expected revert
        }
    }

    // abs(base) < 1 ** high_exponent == 0
    function test_pow_high_exponent(int128 x, uint256 a) public {
        a = between(a, 2 ** 64 + 1, type(uint256).max);
        try abdk.abs(x) returns (int128 abs_x) {
            precondition(abs_x < ONE_FP);

            int128 result = abdk.pow(x, a);

            assertEq(result, ZERO_FP);
        } catch {}
    }
}
