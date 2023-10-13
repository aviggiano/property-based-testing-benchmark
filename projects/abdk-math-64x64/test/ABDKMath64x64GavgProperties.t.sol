// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64GavgProperties is ABDKMath64x64Setup {
    // gavg(x, y) >= min(x, y) && gavg(x, y) <= max(x, y)
    function test_gavg_values_in_range(int128 x, int128 y) public {
        try abdk.gavg(x, y) returns (int128 gavg_xy) {
            if (x == ZERO_FP || y == ZERO_FP) {
                assertEq(gavg_xy, ZERO_FP);
            } else {
                try abdk.abs(x) returns (int128 abs_x) {
                    try abdk.abs(y) returns (int128 abs_y) {
                        if (abs_x >= abs_y) {
                            assertTrue(gavg_xy >= abs_y && gavg_xy <= abs_x);
                        } else {
                            assertTrue(gavg_xy >= abs_x && gavg_xy <= abs_y);
                        }
                    } catch {}
                } catch {}
            }
        } catch {}
    }

    // gavg(x, x) == | x |
    function test_gavg_one_value(int128 x) public {
        try abdk.gavg(x, x) returns (int128 gavg_x) {
            assertEq(gavg_x, abdk.abs(x));
        } catch {}
    }

    // gavg(x, y) == gavg(y, x)
    function test_gavg_operand_order(int128 x, int128 y) public {
        try abdk.gavg(x, y) returns (int128 gavg_xy) {
            try abdk.gavg(y, x) returns (int128 gavg_yx) {
                assertEq(gavg_xy, gavg_yx);
            } catch {}
        } catch {}
    }

    // gavg(MAX,MAX) == MAX
    function test_gavg_maximum() public {
        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MAX_64x64
        try abdk.gavg(MAX_64x64, MAX_64x64) returns (int128 result) {
            assertEq(result, MAX_64x64);
        } catch {}
    }

    // gavg(MIN,MIN) == MIN
    function test_gavg_minimum() public {
        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MIN_64x64
        try abdk.gavg(MIN_64x64, MIN_64x64) returns (int128 result) {
            assertEq(result, MIN_64x64);
        } catch {}
    }
}
