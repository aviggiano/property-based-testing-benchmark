pragma solidity ^0.8.0;

import "@crytic/properties/contracts/util/PropertiesHelper.sol";
import "./Asserts.sol";

contract CryticAsserts is PropertiesAsserts, Asserts {
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
        assertGte(a, b, reason);
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
        assertLte(a, b, reason);
    }

    function eq(
        uint256 a,
        uint256 b,
        string memory reason
    ) internal virtual override {
        assertEq(a, b, reason);
    }

    function t(bool b, string memory reason) internal virtual override {
        assertWithMsg(b, reason);
    }

    function between(
        uint256 value,
        uint256 low,
        uint256 high
    ) internal virtual override returns (uint256) {
        return clampBetween(value, low, high);
    }

    function between(
        int256 value,
        int256 low,
        int256 high
    ) internal virtual override returns (int256) {
        return clampBetween(value, low, high);
    }

    function precondition(
        bool p
    ) internal virtual override {
        require(p);
    }
}
