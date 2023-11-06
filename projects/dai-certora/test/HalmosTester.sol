// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {TargetFunctions} from "./TargetFunctions.sol";
import {HalmosAsserts} from "chimera/HalmosAsserts.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

contract HalmosTester is TargetFunctions, SymTest, HalmosAsserts {
    function setUp() public {
        setup();
    }

    function check_minivat_n_full_symbolic(bytes4[] memory selectors) public {
        for (uint256 i = 0; i < selectors.length; ++i) {
            assumeValidSelector(selectors[i]);
            assumeSuccessfulCall(selectors[i]);
        }

        assertEq(
            minivat.debt(),
            minivat.Art() * minivat.rate(),
            "The Fundamental Equation of DAI"
        );
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

    function assumeSuccessfulCall(bytes4 selector) internal {
        if (selector == minivat.init.selector) {
            this.init();
        } else if (selector == minivat.move.selector) {
            address dst = svm.createAddress("dst");
            int256 wad = svm.createInt256("wad");
            this.move(dst, wad);
        } else if (selector == minivat.frob.selector) {
            int256 dart = svm.createInt256("dart");
            this.frob(dart);
        } else if (selector == minivat.fold.selector) {
            int256 delta = svm.createInt256("delta");
            this.fold(delta);
        } else {
            // selector bytes4(0) means "skip this call"
        }
    }
}
