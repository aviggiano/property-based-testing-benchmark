// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {TargetFunctions} from "./TargetFunctions.sol";
import {FoundryAsserts} from "chimera/FoundryAsserts.sol";

contract FoundryTester is TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
    }
}
