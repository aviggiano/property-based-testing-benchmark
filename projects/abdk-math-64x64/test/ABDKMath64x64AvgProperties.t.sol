// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64ConversionProperties is ABDKMath64x64Setup {
    // avg(x, y) >= min(x, y) && avg(x, y) <= max(x, y)
    function test_avg_values_in_range(int128 x, int128 y) public {
        try abdk.avg(x, y) returns (int128 avg_xy) {
            if (x >= y) {
                assertTrue(avg_xy >= y && avg_xy <= x);
            } else {
                assertTrue(avg_xy >= x && avg_xy <= y);
            }
        } catch {}
    }

    // avg(x, x) == x
    function test_avg_one_value(int128 x) public {
        try abdk.avg(x, x) returns (int128 avg_x) {
            assertEq(avg_x, x);
        } catch {}
    }

    // avg(x, y) == avg(y, x)
    function test_avg_operand_order(int128 x, int128 y) public {
        try abdk.avg(x, y) returns (int128 avg_xy) {
            try abdk.avg(y, x) returns (int128 avg_yx) {
                assertEq(avg_xy, avg_yx);
            } catch {}
        } catch {}
    }

    // avg(MAX,MAX) == MAX
    function test_avg_maximum() public {
        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MAX_64x64
        try abdk.avg(MAX_64x64, MAX_64x64) returns (int128 result) {
            assertEq(result, MAX_64x64);
        } catch {}
    }

    // avg(MIN,MIN) == MIN
    function test_avg_minimum() public {
        // This may revert due to overflow depending on implementation
        // If it doesn't revert, the result must be MIN_64x64
        try abdk.avg(MIN_64x64, MIN_64x64) returns (int128 result) {
            assertEq(result, MIN_64x64);
        } catch {}
    }
}
