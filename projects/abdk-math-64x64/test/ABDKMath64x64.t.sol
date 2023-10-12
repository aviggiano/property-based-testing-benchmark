// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@abdk/ABDKMath64x64.sol";

contract ABDKMath64x64Test is Test {
    function setUp() public {}

    function test_from_int_identity(int256 x) public {
        vm.assume(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
        assertEq(ABDKMath64x64.toInt(ABDKMath64x64.fromInt(x)), x);
    }

    function test_from_uint_identity(uint256 x) public {
        vm.assume(x <= 0x7FFFFFFFFFFFFFFF);
        assertEq(ABDKMath64x64.toUInt(ABDKMath64x64.fromUInt(x)), x);
    }
}
