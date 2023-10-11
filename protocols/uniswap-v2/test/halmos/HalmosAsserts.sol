pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../Asserts.sol";

contract HalmosAsserts is Test, Asserts {
    function gt(uint256 a, uint256 b, string memory) internal virtual override {
        assert(a > b);
    }

    function gte(
        uint256 a,
        uint256 b,
        string memory
    ) internal virtual override {
        assert(a >= b);
    }

    function lt(uint256 a, uint256 b, string memory) internal virtual override {
        assert(a < b);
    }

    function lte(
        uint256 a,
        uint256 b,
        string memory
    ) internal virtual override {
        assert(a <= b);
    }

    function eq(uint256 a, uint256 b, string memory) internal virtual override {
        assert(a == b);
    }

    function t(bool b, string memory) internal virtual override {
        assert(b);
    }

    function between(
        uint256 value,
        uint256 low,
        uint256 high
    ) internal virtual override returns (uint256) {
        vm.assume(value >= low && value <= high);
        return value;
    }

    function precondition(
        bool p
    ) internal virtual override {
        vm.assume(p);
    }
}
