// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64AddProperties is ABDKMath64x64Setup {
    // x + y == y + x
    function test_add_commutative(int128 x, int128 y) public {
        try abdk.add(x, y) returns (int128 x_y) {
            try abdk.add(y, x) returns (int128 y_x) {
                assertEq(x_y, y_x);
            } catch {}
        } catch {}
    }

    // (x + y) + z == x + (y + z)
    function test_add_test_associative(int128 x, int128 y, int128 z) public {
        try abdk.add(x, y) returns (int128 x_y) {
            try abdk.add(y, z) returns (int128 y_z) {
                try abdk.add(x, y_z) returns (int128 xy_z) {
                    try abdk.add(x_y, z) returns (int128 x_yz) {
                        assertEq(xy_z, x_yz);
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // x + 0 == x (equivalent to x + (-x) == 0)
    function test_add_identity(int128 x) public {
        try abdk.add(x, ZERO_FP) returns (int128 x_0) {
            assertEq(x_0, x);
            try abdk.neg(x) returns (int128 x_neg) {
                try abdk.add(x, x_neg) returns (int128 x_x_neg) {
                    assertEq(ZERO_FP, x_x_neg);
                } catch {}
            } catch {}
        } catch {}
    }

    // x + y >= x <=> y >= 0; x + y < x <=> y < 0
    function test_add_values(int128 x, int128 y) public {
        try abdk.add(x, y) returns (int128 x_y) {
            if (y >= ZERO_FP) {
                assertGe(x_y, x);
            } else {
                assertLt(x_y, x);
            }
        } catch {}
    }

    // x + y <= MAX && x + y >= MIN
    function test_add_range(int128 x, int128 y) public {
        int128 result;
        try abdk.add(x, y) {
            result = abdk.add(x, y);
            assertLe(result, MAX_64x64);
            assertGe(result, MIN_64x64);
        } catch {
            // If it reverts, just ignore
        }
    }

    // MAX + 0 == MAX
    function test_add_maximum_value() public {
        int128 result;
        try abdk.add(MAX_64x64, ZERO_FP) {
            // Expected behaviour, does not revert
            result = abdk.add(MAX_64x64, ZERO_FP);
            assertEq(result, MAX_64x64);
        } catch {
            assertTrue(false);
        }
    }

    // MAX + 1 reverts
    function test_add_maximum_value_plus_one() public {
        try abdk.add(MAX_64x64, ONE_FP) {
            assertTrue(false);
        } catch {
            // Expected behaviour, reverts
        }
    }

    // MIN + 0 == MIN
    function test_add_minimum_value() public {
        int128 result;
        try abdk.add(MIN_64x64, ZERO_FP) {
            // Expected behaviour, does not revert
            result = abdk.add(MIN_64x64, ZERO_FP);
            assertEq(result, MIN_64x64);
        } catch {
            assertTrue(false);
        }
    }

    // MAX - 1 reverts
    function test_add_minimum_value_plus_negative_one() public {
        try abdk.add(MIN_64x64, MINUS_ONE_FP) {
            assertTrue(false);
        } catch {
            // Expected behaviour, reverts
        }
    }
}
