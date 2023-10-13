// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64NegProperties is ABDKMath64x64Setup {
    // -(-x) == x
    function test_neg_double_negation(int128 x) public {
        try abdk.neg(x) returns (int128 neg_x) {
            assertEq(abdk.neg(neg_x), x);
        } catch {}
    }

    // x + (-x) == 0
    function test_neg_identity(int128 x) public {
        try abdk.neg(x) returns (int128 neg_x) {
            assertEq(abdk.add(x, neg_x), ZERO_FP);
        } catch {}
    }

    // -0 == 0
    function test_neg_zero() public {
        int128 neg_x = abdk.neg(ZERO_FP);

        assertEq(neg_x, ZERO_FP);
    }

    // Test for the maximum value case
    // Since this is implementation-dependant, we will actually test with MAX_64x64-EPS
    function test_neg_maximum() public {
        try abdk.neg(abdk.sub(MAX_64x64, EPSILON)) {
            // Expected behaviour, does not revert
        } catch {
            assertTrue(false);
        }
    }

    // Test for the minimum value case
    // Since this is implementation-dependant, we will actually test with MIN_64x64+EPS
    function test_neg_minimum() public {
        try abdk.neg(abdk.add(MIN_64x64, EPSILON)) {
            // Expected behaviour, does not revert
        } catch {
            assertTrue(false);
        }
    }
}
