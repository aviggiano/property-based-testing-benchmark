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

    function test_minivat_seq_symbolic_selectors(
        bytes4 sel1,
        bytes4 sel2,
        bytes4 sel3,
        bytes4 sel4
    ) public {
        assumeSuccessfulCall(address(minivat), abi.encodeWithSelector(sel1));
        assumeSuccessfulCall(
            address(minivat),
            abi.encodeWithSelector(sel2, 10 ** 18)
        );
        assumeSuccessfulCall(
            address(minivat),
            abi.encodeWithSelector(sel3, -10 ** 27)
        );
        assumeSuccessfulCall(address(minivat), abi.encodeWithSelector(sel4));

        assert(minivat.debt() == minivat.Art() * minivat.rate());
    }

    function test_minivat_seq_full_symbolic(
        bytes4 sel1,
        bytes4 sel2,
        bytes4 sel3,
        bytes4 sel4
    ) public {
        assumeSuccessfulCall(address(minivat), calldataFor(sel1));
        assumeSuccessfulCall(address(minivat), calldataFor(sel2));
        assumeSuccessfulCall(address(minivat), calldataFor(sel3));
        assumeSuccessfulCall(address(minivat), calldataFor(sel4));

        assert(minivat.debt() == minivat.Art() * minivat.rate());
    }

    function test_minivat_n_symbolic_selectors(uint256 n) public {
        vm.assume(n <= 4);
        bytes4[] memory sel = selectors(n);

        for (uint256 i = 0; i < n; ++i) {
            assumeSuccessfulCall(address(minivat), concreteCalldataFor(sel[i]));
        }

        assert(minivat.debt() == minivat.Art() * minivat.rate());
    }

    function selectors(uint256 n) private returns (bytes4[] memory ans) {
        ans = new bytes4[](n);
        for (uint256 i = 0; i < n; ++i) {
            ans[i] = svm.createBytes4(string.concat("sel", str(i + 1)));
        }
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
            revert();
            // return svm.createBytes(1024, "data");
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
        } else {
            revert();
            // return svm.createBytes(1024, "data");
        }
    }

    function assumeValidSelector(bytes4 selector) internal {
        vm.assume(
            selector == minivat.init.selector ||
                selector == minivat.frob.selector ||
                selector == minivat.fold.selector ||
                selector == minivat.move.selector
        );
    }

    function assumeSuccessfulCall(address target, bytes memory data) internal {
        bool success;
        (success, ) = target.call(data);
        vm.assume(success);
    }

    function str(uint256 i) internal returns (string memory) {
        return
            i == 0 ? "0" : i == 1 ? "1" : i == 2 ? "2" : i == 3 ? "3" : i == 4
                ? "4"
                : i == 5
                ? "5"
                : "6+";
    }
}
