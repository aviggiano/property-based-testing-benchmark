pragma solidity ^0.8.0;

abstract contract Asserts {
    function gt(uint256 a, uint256 b, string memory reason) internal virtual;

    function gte(uint256 a, uint256 b, string memory reason) internal virtual;

    function lt(uint256 a, uint256 b, string memory reason) internal virtual;

    function lte(uint256 a, uint256 b, string memory reason) internal virtual;

    function eq(uint256 a, uint256 b, string memory reason) internal virtual;

    function t(bool b, string memory reason) internal virtual;

    function between(uint256 value, uint256 low, uint256 high) internal virtual returns(uint256);
}
