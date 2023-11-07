// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {HalmosAsserts} from "chimera/HalmosAsserts.sol";

import "../src/Vat.sol";

contract VatTest is Test, HalmosAsserts {
    Vat vat;
    bytes32 ilk;

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;

    function ray(uint256 wad) internal pure returns (uint256) {
        return wad * RAY;
    }

    function rad(uint256 wad) internal pure returns (uint256) {
        return wad * RAD;
    }

    function setUp() public {
        vat = new Vat();
        ilk = "gems";

        vat.init("gems");
        vat.file("gems", "spot", ray(0.5 ether));
        vat.file("gems", "line", rad(1000 ether));
        vat.file("Line", rad(1000 ether));
    }

    function check_vat_counterexample(
        int256 var1,
        int256 var2,
        int256 var3,
        int256 var4
    ) external {
        var1 = between(var1, -10 * int256(WAD), 10 * int256(WAD));
        var2 = between(var2, -10 * int256(WAD), 10 * int256(WAD));
        var3 = between(var3, -10 * int256(WAD), 10 * int256(WAD));
        var4 = between(var4, -2 * int256(RAY), 2 * int256(RAY));
        address me = address(this);

        // var1 = 8 ether;
        // var2 = 4 ether;
        // var3 = 4 ether;
        // var4 = -int256(RAY);

        vat.slip(ilk, me, var1);
        vat.frob(ilk, me, me, me, var2, var3);
        vat.fold(ilk, me, var4);
        vat.init(ilk);
        assertEq(
            vat.debt(),
            vat.Art(ilk) * vat.rate(ilk),
            "The Fundamental Equation of DAI"
        );
    }
}
