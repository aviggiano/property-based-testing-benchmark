// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {TargetFunctions} from "./TargetFunctions.sol";
import {CryticAsserts} from "chimera/CryticAsserts.sol";

contract CryticTester is TargetFunctions, CryticAsserts {
    constructor() {
        setup();
    }
}
