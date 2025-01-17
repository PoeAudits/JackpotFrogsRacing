// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { Test } from "lib/forge-std/src/Test.sol";
import { TargetFunctions } from "./TargetFunctions.sol";
import { FoundryAsserts } from "lib/chimera/src/FoundryAsserts.sol";
import "lib/forge-std/src/console2.sol";

contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
  function setUp() public {
    setup();

    targetContract(address(target));
  }

  function test_crytic() public {
    // TODO: add failing property tests here for debugging
  }
}
