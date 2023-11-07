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

    function test_minivat_counterexample(int64 x, int96 y) public {
        // int256, int256
        // x = 10 ** 18
        // y = -10 ** 27


        // NOTE: Halmos does not finish in 1h using (int256, int256), but it does in 16s using (int64, int96)
        // Counterexample:
        //     p_x_int64 = 0x0000000000000000000000000000000000000000000000005e96bb957dca0ee7 (6815841336806739687)
        //     p_y_int96 = 0xfffffffffffffffffffffffffffffffffffffffffcc4d1c3602f7fc318000000 (-1000000000000000000000000000)

        try minivat.init() {} catch {
            vm.assume(false);
        }
        try minivat.frob(x) {} catch {
            vm.assume(false);
        }
        try minivat.fold(y) {} catch {
            vm.assume(false);
        }
        try minivat.init() {} catch {
            vm.assume(false);
        }

        assertEq(
            minivat.debt(),
            minivat.Art() * minivat.rate(),
            "The Fundamental Equation of DAI"
        );
    }

    function test_minivat_counterexample_2_calls() public {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = minivat.frob.selector;
        selectors[1] = minivat.init.selector;
        test_minivat_n_symbolic_selectors(selectors);
    }


    function check_minivat_counterexample_4_calls() public {
        check_minivat_seq_full_symbolic(
            minivat.init.selector,
            minivat.frob.selector,
            minivat.fold.selector,
            minivat.init.selector
        );
    }

    function test_minivat_seq_symbolic_selectors(
        bytes4 sel1,
        bytes4 sel2,
        bytes4 sel3,
        bytes4 sel4
    ) public {
        assumeValidSelector(sel1);
        assumeValidSelector(sel2);
        assumeValidSelector(sel3);
        assumeValidSelector(sel4);

        assumeSuccessfulCall(address(minivat), concreteCalldataFor(sel1));
        assumeSuccessfulCall(address(minivat), concreteCalldataFor(sel2));
        assumeSuccessfulCall(address(minivat), concreteCalldataFor(sel3));
        assumeSuccessfulCall(address(minivat), concreteCalldataFor(sel4));

        assertEq(
            minivat.debt(),
            minivat.Art() * minivat.rate(),
            "The Fundamental Equation of DAI"
        );
    }

    function test_minivat_n_symbolic_selectors(
        bytes4[] memory selectors
    ) public {
        for (uint256 i = 0; i < selectors.length; ++i) {
            assumeValidSelector(selectors[i]);
            if (selectors[i] != bytes4(0)) {
                assumeSuccessfulCall(
                    address(minivat),
                    concreteCalldataFor(selectors[i])
                );
            }
        }

        assertEq(
            minivat.debt(),
            minivat.Art() * minivat.rate(),
            "The Fundamental Equation of DAI"
        );
    }

    function check_minivat_seq_full_symbolic(
        bytes4 sel1,
        bytes4 sel2,
        bytes4 sel3,
        bytes4 sel4
    ) public {
        assumeSuccessfulCall(address(minivat), calldataFor(sel1));
        assumeSuccessfulCall(address(minivat), calldataFor(sel2));
        assumeSuccessfulCall(address(minivat), calldataFor(sel3));
        assumeSuccessfulCall(address(minivat), calldataFor(sel4));

        assertEq(
            minivat.debt(),
            minivat.Art() * minivat.rate(),
            "The Fundamental Equation of DAI"
        );
    }

    function check_minivat_n_full_symbolic(bytes4[] memory selectors) public {
        for (uint256 i = 0; i < selectors.length; ++i) {
            assumeValidSelector(selectors[i]);
            assumeSuccessfulCall(address(minivat), calldataFor(selectors[i]));
        }

        assertEq(
            minivat.debt(),
            minivat.Art() * minivat.rate(),
            "The Fundamental Equation of DAI"
        );
    }

    function calldataFor(bytes4 selector) internal view returns (bytes memory) {
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
            return svm.createBytes(1024, "data");
        }
    }

    function concreteCalldataFor(
        bytes4 selector
    ) internal view returns (bytes memory) {
        if (selector == minivat.init.selector) {
            return abi.encodeWithSelector(selector);
        } else if (selector == minivat.move.selector) {
            return abi.encodeWithSelector(selector, address(0), 10 ** 18);
        } else if (selector == minivat.frob.selector) {
            return abi.encodeWithSelector(selector, 10 ** 18);
        } else if (selector == minivat.fold.selector) {
            return abi.encodeWithSelector(selector, -10 ** 27);
        } else if (selector == bytes4(0)) {
            return abi.encodeWithSelector(selector);
        } else {
            revert();
        }
    }

    function assumeValidSelector(bytes4 selector) internal view {
        vm.assume(
            selector == minivat.init.selector ||
                selector == minivat.frob.selector ||
                selector == minivat.fold.selector ||
                selector == minivat.move.selector ||
                selector == bytes4(0)
        );
    }

    function assumeSuccessfulCall(address target, bytes memory data) internal {
        // selector bytes4(0) means "skip this call"
        if (keccak256(data) == keccak256(abi.encodeWithSelector(bytes4(0)))) return;

        bool success;
        (success, ) = target.call(data);
        vm.assume(success);
    }
}
