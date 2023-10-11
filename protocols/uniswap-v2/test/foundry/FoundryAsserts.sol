pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../Asserts.sol";

contract FoundryAsserts is Test, Asserts {
    function gt(
        uint256 a,
        uint256 b,
        string memory reason
    ) internal virtual override {
        assertGt(a, b, reason);
    }

    function gte(
        uint256 a,
        uint256 b,
        string memory reason
    ) internal virtual override {
        assertGe(a, b, reason);
    }

    function lt(
        uint256 a,
        uint256 b,
        string memory reason
    ) internal virtual override {
        assertLt(a, b, reason);
    }

    function lte(
        uint256 a,
        uint256 b,
        string memory reason
    ) internal virtual override {
        assertLe(a, b, reason);
    }

    function eq(
        uint256 a,
        uint256 b,
        string memory reason
    ) internal virtual override {
        assertEq(a, b, reason);
    }

    function t(bool b, string memory reason) internal virtual override {
        assertTrue(b, reason);
    }

    function between(
        uint256 value,
        uint256 low,
        uint256 high
    ) internal virtual override returns (uint256) {
        if (value < low || value > high) {
            uint ans = low + (value % (high - low + 1));
            return ans;
        }
        return value;
    }
}
