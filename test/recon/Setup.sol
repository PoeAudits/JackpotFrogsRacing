// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "lib/chimera/src/BaseSetup.sol";
import "src/Singleton.sol";

abstract contract Setup is BaseSetup {
    Singleton public target;

    function setup() internal virtual override {
        target = new Singleton();
    }
}
