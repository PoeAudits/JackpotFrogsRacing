// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { Asserts } from "lib/chimera/src/Asserts.sol";
import { Setup } from "./Setup.sol";

abstract contract Properties is Setup, Asserts {
  // example property test that gets run after each call in sequence
  function invariant_max_racers() public returns (bool) {
    uint256 max_racers = target.MAX_RACERS();
    uint256 nextRace = target.nextRace();
    if (max_racers < target.races(nextRace)) {
      return false;
    }
    if (max_racers < target.races(nextRace - 1)) {
      return false;
    }
    if (max_racers < target.races(nextRace + 1)) {
      return false;
    }
    if (max_racers < target.races(nextRace + 2)) {
      return false;
    }
    return true;
  }
}
