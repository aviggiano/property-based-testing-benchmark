// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64DivProperties is ABDKMath64x64Setup {
    // x / 1 == x
    // x / x == 1 unless x == 0
    function test_div_division_identity(int128 x) public {
        try abdk.div(x, ONE_FP) returns (int128 div_1) {
            assertEq(x, div_1);
        } catch {}

        try abdk.div(x, x) returns (int128 div_x) {
            // This should always equal one
            div_x = abdk.div(x, x);
            assertEq(div_x, ONE_FP);
        } catch {
            // The only allowed case to revert is if x == 0
            assertEq(x, ZERO_FP);
        }
    }

    // x / -y == -(x / y)
    function test_div_negative_divisor(int128 x, int128 y) public {
        vm.assume(y < ZERO_FP);

        try abdk.div(x, y) returns (int128 x_y) {
            try abdk.neg(y) returns (int128 neg_y) {
                try abdk.div(x, neg_y) returns (int128 x_neg_y) {
                    assertEq(x_y, abdk.neg(x_neg_y));
                } catch {}
            } catch {}
        } catch {}
    }

    // 0 / x = 0
    function test_div_division_num_zero(int128 x) public {
        vm.assume(x != ZERO_FP);

        int128 div_0 = abdk.div(ZERO_FP, x);

        assertEq(ZERO_FP, div_0);
    }

    // x / y >= x <=> |y| <= 1; x / y < x <=> |y| > 1
    function test_div_values(int128 x, int128 y) public {
        vm.assume(y != ZERO_FP);

        try abdk.div(x, y) returns (int128 x_y) {
            try abdk.abs(x_y) returns (int128 abs_x_y) {
                try abdk.abs(x) returns (int128 abs_x) {
                    try abdk.abs(y) returns (int128 abs_y) {
                        if (abs_y <= ONE_FP) {
                            assertGe(abs_x_y, abs_x);
                        } else {
                            assertLe(abs_x_y, abs_x);
                        }
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // x/0 reverts
    function test_div_div_by_zero(int128 x) public {
        try abdk.div(x, ZERO_FP) {
            assertTrue(false);
        } catch {
            // Expected revert
        }
    }

    // x/MAX <= 1
    function test_div_maximum_denominator(int128 x) public {
        try abdk.div(x, MAX_64x64) returns (int128 div_large) {
            assertLe(abdk.abs(div_large), ONE_FP);
        } catch {
            // Expected revert
        }
    }

    // MAX/x >= 1 <=> |x| >= 1
    function test_div_maximum_numerator(int128 x) public {
        try abdk.div(MAX_64x64, x) {
            // If it didn't revert, then |x| >= 1
            try abdk.abs(x) returns (int128 abs_x) {
                assertGe(abs_x, ONE_FP);
            } catch {}
        } catch {
            // Expected revert as result is higher than max
        }
    }

    // x / y <= MAX && x / y >= MIN
    function test_div_range(int128 x, int128 y) public {
        int128 result;

        try abdk.div(x, y) {
            // If it returns a value, it must be in range
            result = abdk.div(x, y);
            assertTrue(result <= MAX_64x64 && result >= MIN_64x64);
        } catch {
            // Otherwise, it should revert
        }
    }
}
