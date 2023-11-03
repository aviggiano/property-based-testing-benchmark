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

    function test_minivat_counterexample_2() public {
        test_minivat_seq_full_symbolic(
            minivat.init.selector,
            minivat.frob.selector,
            minivat.fold.selector,
            minivat.init.selector
        );
    }


    function test_minivat_seq_symbolic_selectors(bytes4 sel1, bytes4 sel2, bytes4 sel3, bytes4 sel4) public {
        assumeSuccessfulCall(address(minivat), abi.encodeWithSelector(sel1));
        assumeSuccessfulCall(address(minivat), abi.encodeWithSelector(sel2, 10 ** 18));
        assumeSuccessfulCall(address(minivat), abi.encodeWithSelector(sel3, -10 ** 27));
        assumeSuccessfulCall(address(minivat), abi.encodeWithSelector(sel4));

        assert(minivat.debt() == minivat.Art() * minivat.rate());
    }


    function test_minivat_seq_full_symbolic(
        bytes4 sel1,
        bytes4 sel2,
        bytes4 sel3,
        bytes4 sel4
    ) public {
        assumeSuccessfulCall(address(minivat), _calldataFor(sel1));
        assumeSuccessfulCall(address(minivat), _calldataFor(sel2));
        assumeSuccessfulCall(address(minivat), _calldataFor(sel3));
        assumeSuccessfulCall(address(minivat), _calldataFor(sel4));

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

    function assumeSuccessfulCall(address target, bytes memory data) internal {
        bool success;
        (success, ) = target.call(data);
        vm.assume(success);
    }
}
