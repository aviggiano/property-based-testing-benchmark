// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@abdk/ABDKMath64x64.sol";
import "./ABDKMath64x64Wrapper.sol";

// https://github.com/crytic/properties/blob/d573bf661990f11cc033e2b5b749deec962b5243/contracts/Math/ABDKMath64x64/ABDKMath64x64PropertyTests.sol
contract ABDKMath64x64Setup is Test {
    ABDKMath64x64Wrapper internal abdk;

    int128 internal ZERO_FP = ABDKMath64x64.fromInt(0);
    int128 internal ONE_FP = ABDKMath64x64.fromInt(1);
    int128 internal MINUS_ONE_FP = ABDKMath64x64.fromInt(-1);
    int128 internal TWO_FP = ABDKMath64x64.fromInt(2);
    int128 internal THREE_FP = ABDKMath64x64.fromInt(3);
    int128 internal EIGHT_FP = ABDKMath64x64.fromInt(8);
    int128 internal THOUSAND_FP = ABDKMath64x64.fromInt(1000);
    int128 internal MINUS_SIXTY_FOUR_FP = ABDKMath64x64.fromInt(-64);
    int128 internal EPSILON = 1;
    int128 internal ONE_TENTH_FP =
        ABDKMath64x64.div(ABDKMath64x64.fromInt(1), ABDKMath64x64.fromInt(10));

    uint256 internal REQUIRED_SIGNIFICANT_BITS = 10;

    int128 internal constant MIN_64x64 = -0x80000000000000000000000000000000;
    int128 internal constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256 internal constant MAX_256 =
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    int256 internal constant MIN_256 =
        -0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant MAX_U256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function setUp() public {
        abdk = new ABDKMath64x64Wrapper();
    }
}
