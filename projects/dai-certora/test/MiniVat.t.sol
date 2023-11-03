// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

import "../src/MiniVat.sol";

contract MiniVatTest is Test, SymTest {
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
        (success, ) = address(minivat).call(
            abi.encodeWithSelector(second, 10 ** 18)
        );
        vm.assume(success);
        (success, ) = address(minivat).call(
            abi.encodeWithSelector(third, -10 ** 27)
        );
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

        (success, ) = address(minivat).call(abi.encodeWithSelector(first));
        vm.assume(success);
        (success, ) = address(minivat).call(
            abi.encodeWithSelector(second, 10 ** 18)
        );
        vm.assume(success);
        (success, ) = address(minivat).call(
            abi.encodeWithSelector(third, -10 ** 27)
        );
        vm.assume(success);
        (success, ) = address(minivat).call(abi.encodeWithSelector(fourth));
        vm.assume(success);

        assert(minivat.debt() == minivat.Art() * minivat.rate());
    }

    function test_minivat_seq_full_symbolic(
        bytes4 first,
        bytes4 second,
        bytes4 third,
        bytes4 fourth
    ) external {
        bool success;

        (success, ) = address(minivat).call(_calldataFor(first));
        vm.assume(success);
        (success, ) = address(minivat).call(_calldataFor(second));
        vm.assume(success);
        (success, ) = address(minivat).call(_calldataFor(third));
        vm.assume(success);
        (success, ) = address(minivat).call(_calldataFor(fourth));
        vm.assume(success);

        assert(minivat.debt() == minivat.Art() * minivat.rate());
    }

    function _calldataFor(
        bytes4 selector
    ) internal view returns (bytes memory) {
        if (selector == minivat.init.selector) {
            return abi.encodeWithSelector(selector);
        } else if (selector == minivat.move.selector) {
            return
                abi.encodeWithSelector(
                    selector,
                    svm.createAddress("dst"),
                    svm.createInt256("wad")
                );
        } else if (selector == minivat.frob.selector) {
            return abi.encodeWithSelector(selector, svm.createInt256("dart"));
        } else if (selector == minivat.fold.selector) {
            return abi.encodeWithSelector(selector, svm.createInt256("delta"));
        } else {
            revert();
            // return svm.createBytes(1024, "data");
        }
    }
}
