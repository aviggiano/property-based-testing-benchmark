// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ABDKMath64x64Setup.t.sol";

contract ABDKMath64x64ConversionProperties is ABDKMath64x64Setup {
    // toInt(fromInt(x)) == x
    function test_from_int_identity(int256 x) public {
        x = between(x, -0x8000000000000000, 0x7FFFFFFFFFFFFFFF);
        assertEq(abdk.toInt(abdk.fromInt(x)), x);
    }

    // toUInt(fromUInt(x)) == x
    function test_from_uint_identity(uint256 x) public {
        x = between(x, 0, 0x7FFFFFFFFFFFFFFF);
        assertEq(abdk.toUInt(abdk.fromUInt(x)), x);
    }
}
