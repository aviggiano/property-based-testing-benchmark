// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64Log_2Properties is ABDKMath64x64Setup {
    // log_2(x * y) = log_2(x) + log2(y)
    function test_log_2_distributive_mul(int128 x, int128 y) public {
        // Ensure we have enough significant digits for the result to be meaningful
        try abdk.significant_bits_after_mul(x, y) returns (uint256 s__x__y) {
            vm.assume(s__x__y > REQUIRED_SIGNIFICANT_BITS);
            try abdk.log_2(x) returns (int128 log_2_x) {
                try abdk.log_2(y) returns (int128 log_2_y) {
                    try abdk.mul(x, y) returns (int128 xy) {
                        try abdk.log_2(xy) returns (int128 log_2_xy) {
                            try abdk.add(log_2_x, log_2_y) returns (
                                int128 log_2_x_log_2_y
                            ) {
                                try abdk.abs(log_2_x_log_2_y) returns (
                                    int128 abs_log_2_x_log_2_y
                                ) {
                                    // The maximum loss of precision is given by the formula:
                                    // | log_2(x) + log_2(y) |
                                    uint256 loss = abdk.toUInt(
                                        abs_log_2_x_log_2_y
                                    );

                                    try
                                        abdk.equal_within_precision(
                                            log_2_xy,
                                            log_2_x_log_2_y,
                                            loss
                                        )
                                    returns (bool equal) {
                                        assertTrue(equal);
                                    } catch {}
                                } catch {}
                            } catch {}
                        } catch {}
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // log_2(x ** y) = y * log_2(x)
    function test_log_2_power(int128 x, uint256 y) public {
        try abdk.log_2(x) returns (int128 log_2_x) {
            try abdk.pow(x, y) returns (int128 x_y) {
                try abdk.log_2(x_y) returns (int128 log_2_x_y) {
                    try abdk.mulu(log_2_x, y) returns (uint256 y_log_2_x) {
                        assertEq(y_log_2_x, abdk.toUInt(log_2_x_y));
                    } catch {}
                } catch {}
            } catch {}
        } catch {}
    }

    // log_2(0) reverts
    function test_log_2_zero() public {
        try abdk.log_2(ZERO_FP) {
            // Unexpected, should revert
            assertTrue(false);
        } catch {
            // Expected revert, log(0) is not defined
        }
    }

    // log_2(MAX) > 0
    function test_log_2_maximum() public {
        try abdk.log_2(MAX_64x64) returns(int128 result){
            assertGt(result, ZERO_FP);
        } catch {
            // Unexpected
            assert(false);
        }
    }

    // log_2(x) < 0 reverts if x < 0
    function test_log_2_negative(int128 x) public {
        vm.assume(x < ZERO_FP);

        try abdk.log_2(x) {
            // Unexpected, should revert
            assertTrue(false);
        } catch {
            // Expected
        }
    }
}
