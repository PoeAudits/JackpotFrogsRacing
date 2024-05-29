// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { SingletonHarness } from "src/SingletonHarness.sol";
import { RandomModule } from "src/Modules/RandomModule.sol";
import { UserModule } from "src/Modules/UserModule.sol";
import { RacingModule } from "src/Modules/RacingModule.sol";

contract FactoryHarness {
  SingletonHarness public singleton;
  RandomModule public randomModule;
  RacingModule public racingModule;
  UserModule public userModule;

  constructor() {
    userModule = new UserModule();
    racingModule = new RacingModule();
    randomModule = new RandomModule();
    singleton =
      new SingletonHarness(address(userModule), address(racingModule), address(randomModule));
  }

  function getContracts()
    external
    view
    returns (SingletonHarness, UserModule, RacingModule, RandomModule)
  {
    return (singleton, userModule, racingModule, randomModule);
  }
}
