// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

import "../src/Vat.sol";

contract VatTest is Test {
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
        vat.file("gems", "spot", ray(0.5  ether));
        vat.file("gems", "line", rad(1000 ether));
        vat.file("Line",         rad(1000 ether));
    }

    function test_vat_counterexample(int256 x, int256 y, int256 z, int256 w) external {
        address me = address(this);

        // x = 8 ether;
        // y = 4 ether;
        // z = 4 ether;
        // w = -int256(RAY);

        try vat.slip(ilk, me, x) {} catch {}
        try vat.frob(ilk, me, me, me, y, z) {} catch {}
        try vat.fold(ilk, me, w) {} catch {}
        try vat.init(ilk) {} catch {}
        assertEq(vat.debt(), vat.Art(ilk) * vat.rate(ilk), "The Fundamental Equation of DAI");
    }
}