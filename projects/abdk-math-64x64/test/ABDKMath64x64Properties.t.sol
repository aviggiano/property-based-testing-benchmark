// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@abdk/ABDKMath64x64.sol";
import "./ABDKMath64x64Wrapper.sol";

// https://github.com/crytic/properties/blob/d573bf661990f11cc033e2b5b749deec962b5243/contracts/Math/ABDKMath64x64/ABDKMath64x64PropertyTests.sol
contract ABDKMath64x64Properties is Test {
    ABDKMath64x64Wrapper internal abdk;

    int128 internal ZERO_FP = ABDKMath64x64.fromInt(0);
    int128 internal ONE_FP = ABDKMath64x64.fromInt(1);
    int128 internal MINUS_ONE_FP = ABDKMath64x64.fromInt(-1);
    int128 internal TWO_FP = ABDKMath64x64.fromInt(2);
    int128 internal THREE_FP = ABDKMath64x64.fromInt(3);
    int128 internal EIGHT_FP = ABDKMath64x64.fromInt(8);
    int128 internal THOUSAND_FP = ABDKMath64x64.fromInt(1000);
    int128 internal MINUS_SIXTY_FOUR_FP = ABDKMath64x64.fromInt(-64);
    int128 internal EPSILON = 1;
    int128 internal ONE_TENTH_FP =
        ABDKMath64x64.div(ABDKMath64x64.fromInt(1), ABDKMath64x64.fromInt(10));

    uint256 internal REQUIRED_SIGNIFICANT_BITS = 10;

    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256 private constant MAX_256 =
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256 private constant MIN_256 =
        -0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MAX_U256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function setUp() public {
        abdk = new ABDKMath64x64Wrapper();
    }

    // toInt(fromInt(x)) == x
    function test_from_int_identity(int256 x) public {
        vm.assume(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
        assertEq(abdk.toInt(abdk.fromInt(x)), x);
    }

    // toUInt(fromUInt(x)) == x
    function test_from_uint_identity(uint256 x) public {
        vm.assume(x <= 0x7FFFFFFFFFFFFFFF);
        assertEq(abdk.toUInt(abdk.fromUInt(x)), x);
    }

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
