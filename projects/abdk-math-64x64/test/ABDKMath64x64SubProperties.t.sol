// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64SubProperties is ABDKMath64x64Setup {
    // x - y == x + (-y)
    function test_sub_equivalence_to_addition(int128 x, int128 y) public {
        try abdk.neg(y) returns (int128 minus_y) {
            try abdk.add(x, minus_y) returns (int128 addition) {
                try abdk.sub(x, y) returns (int128 subtraction) {
                    assertEq(addition, subtraction);
                } catch {}
            } catch {}
        } catch {}
    }

    // x - y == -(y - x)
    function test_sub_non_commutative(int128 x, int128 y) public {
        try abdk.sub(x, y) returns (int128 x_y) {
            try abdk.sub(y, x) returns (int128 y_x) {
                try abdk.neg(y_x) returns (int128 neg_y_x) {
                    assertEq(x_y, neg_y_x);
                } catch {}
            } catch {}
        } catch {}
    }

    // x - 0 == x  (equivalent to x - x == 0)
    function test_sub_identity(int128 x) public {
        try abdk.sub(x, ZERO_FP) returns (int128 x_0) {
            assertEq(x_0, x);
            try abdk.sub(x, x) returns (int128 x_x) {
                assertEq(ZERO_FP, x_x);
            } catch {}
        } catch {}
    }

    // (x - y) + y == (x + y) - y == x
    function test_sub_neutrality(int128 x, int128 y) public {
        try abdk.sub(x, y) returns (int128 x_minus_y) {
            try abdk.add(x_minus_y, y) returns (int128 x_minus_y_plus_y) {
                assertEq(x_minus_y_plus_y, x);
                try abdk.add(x, y) returns (int128 x_plus_y) {
                    try abdk.sub(x_plus_y, y) returns (
                        int128 x_plus_y_minus_y
                    ) {
                        assertEq(x_plus_y_minus_y, x);
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // x - y <= x <=> y >= 0; x - y > x <=> y < 0
    function test_sub_values(int128 x, int128 y) public {
        try abdk.sub(x, y) returns (int128 x_y) {
            if (y >= ZERO_FP) {
                assertLe(x_y, x);
            } else {
                assertGt(x_y, x);
            }
        } catch {}
    }

    // x - y <= MAX && x - y >= MIN
    function test_sub_range(int128 x, int128 y) public {
        int128 result;
        try abdk.sub(x, y) {
            result = abdk.sub(x, y);
            assertTrue(result <= MAX_64x64 && result >= MIN_64x64);
        } catch {
            // If it reverts, just ignore
        }
    }

    // MAX - 0 == MAX
    function test_sub_maximum_value() public {
        int128 result;
        try abdk.sub(MAX_64x64, ZERO_FP) {
            // Expected behaviour, does not revert
            result = abdk.sub(MAX_64x64, ZERO_FP);
            assertEq(result, MAX_64x64);
        } catch {
            assertTrue(false);
        }
    }

    // MAX - (-1) reverts
    function test_sub_maximum_value_minus_neg_one() public {
        try abdk.sub(MAX_64x64, MINUS_ONE_FP) {
            assertTrue(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    // MIN - 0 == MIN
    function test_sub_minimum_value() public {
        int128 result;
        try abdk.sub(MIN_64x64, ZERO_FP) {
            // Expected behaviour, does not revert
            result = abdk.sub(MIN_64x64, ZERO_FP);
            assertEq(result, MIN_64x64);
        } catch {
            assertTrue(false);
        }
    }

    // MIN - 1 reverts
    function test_sub_minimum_value_minus_one() public {
        try abdk.sub(MIN_64x64, ONE_FP) {
            assertTrue(false);
        } catch {
            // Expected behaviour, reverts
        }
    }
}
