// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {BaseTargetFunctions} from "chimera/BaseTargetFunctions.sol";
import {MiniVat} from "../src/MiniVat.sol";

/**
 * halmos --function check_minivat_n_full_symbolic --contract HalmosTester -vvv --solver-parallel --solver-timeout-assertion 0 --loop 2
 * forge test --match-contract FoundryTester
 * medusa fuzz --no-color
 * echidna . --contract CryticTester --config config.yaml
 */
abstract contract TargetFunctions is BaseTargetFunctions {
    MiniVat public minivat;
    int256 constant FROB_BOUND = 2 * 10 ** 18;
    int256 constant FOLD_BOUND = 2 * 10 ** 27;
    int256 constant MOVE_BOUND = 2 * 10 ** 18;

    function setup() internal override {
        minivat = new MiniVat();
    }

    function init() public {
        minivat.init();
    }

    function frob(int256 x) public {
        x = between(x, -FROB_BOUND, FROB_BOUND);

        minivat.frob(x);
    }

    function fold(int256 y) public {
        y = between(y, -FOLD_BOUND, FOLD_BOUND);

        minivat.fold(y);
    }

    function move(address dst, int256 wad) public {
        wad = between(wad, -MOVE_BOUND, MOVE_BOUND);

        minivat.move(dst, wad);
    }

    function invariant() public returns (bool) {
        eq(
            minivat.debt(),
            minivat.Art() * minivat.rate(),
            "The Fundamental Equation of DAI"
        );
        return minivat.debt() == minivat.Art() * minivat.rate();
    }
}
