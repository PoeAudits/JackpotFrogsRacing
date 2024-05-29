// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BaseSetup } from "lib/chimera/src/BaseSetup.sol";
import "src/Factory.sol";

abstract contract Setup is BaseSetup {
  Factory public factory;
  Singleton public target;

  UserModule public userModule;
  RacingModule public racingModule;
  RandomModule public randomModule;

  function setup() internal virtual override {
    factory = new Factory();
    (target, userModule, racingModule, randomModule) = factory.getContracts();
  }
}
