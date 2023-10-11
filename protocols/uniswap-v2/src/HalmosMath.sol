pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

contract HalmosMath is Test, SymTest {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function max(uint x, uint y) internal pure returns (uint z) {
        z = x > y ? x : y;
    }

    // https://dapp.org.uk/reports/uniswapv2.html#org1a9132f
    function sqrt(uint y) internal pure returns (uint z) {
        z = svm.createUint256("sqrt_z");
        vm.assume(z * z <= y && (z+1) * (z+1) > y);
    }
}
