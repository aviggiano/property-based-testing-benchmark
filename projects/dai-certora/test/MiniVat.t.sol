// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

import "../src/MiniVat.sol";

contract MiniVatTest is Test {
    MiniVat minivat;

    function setUp() public {
        minivat = new MiniVat();
    }

    function test_minivat_counterexample(int256 x, int256 y) external {
        // x = 10 ** 18
        // y = -10 ** 27

        try minivat.init() {} catch {}
        try minivat.frob(x) {} catch {}
        try minivat.fold(y) {} catch {}
        try minivat.init() {} catch {}
        assert(minivat.debt() == minivat.Art() * minivat.rate());
    }

    function test_minivat_counterexample_2() external {
        bool success;

        bytes4 first = minivat.init.selector;
        bytes4 second = minivat.init.selector;
        bytes4 third = minivat.frob.selector;
        bytes4 fourth = minivat.fold.selector;

        (success, ) = address(minivat).call(abi.encodeWithSelector(first));
        vm.assume(success);
        (success, ) = address(minivat).call(abi.encodeWithSelector(second, 10 ** 18));
        vm.assume(success);
        (success, ) = address(minivat).call(abi.encodeWithSelector(third, -10 ** 27));
        vm.assume(success);
        (success, ) = address(minivat).call(abi.encodeWithSelector(fourth));
        vm.assume(success);
        // assert(minivat.debt() == minivat.Art() * minivat.rate());
    }

    function test_minivat_seq(
        bytes4 first,
        bytes4 second,
        bytes4 third,
        bytes4 fourth
    ) external {
        bool success;
        // x = 10 ** 18
        // y = -10 ** 27
        (success, ) = address(minivat).call(abi.encodeWithSelector(first));
        vm.assume(success);
        (success, ) = address(minivat).call(abi.encodeWithSelector(second, 10 ** 18));
        vm.assume(success);
        (success, ) = address(minivat).call(abi.encodeWithSelector(third, -10 ** 27));
        vm.assume(success);
        (success, ) = address(minivat).call(abi.encodeWithSelector(fourth));
        vm.assume(success);

        assert(minivat.debt() == minivat.Art() * minivat.rate());
    }
}
