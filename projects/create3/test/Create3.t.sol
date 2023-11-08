// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

import "../src/Deployer.sol";
import "../src/Counter.sol";

contract Create3Test is Test {
    Deployer deployer;
    Counter counter;

    function setUp() public {
        deployer = new Deployer();
    }

    function test_create3() public {
        Deployer.Addresses memory addr = deployer.getFutureAddresses();

        counter =
            Counter(deployer.deploy(deployer.COUNTER(), abi.encodePacked(type(Counter).creationCode, abi.encode(1337))));

        assertTrue(address(counter) != address(0));
        assertTrue(address(counter) == addr.counterAddress);
    }
}
