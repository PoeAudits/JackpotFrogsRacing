// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Singleton } from "src/Singleton.sol";
import { UserModule } from "src/Modules/UserModule.sol";
import { RacingModule } from "src/Modules/RacingModule.sol";
import { RandomModule } from "src/Modules/RandomModule.sol";

contract Factory {
  Singleton internal singleton;

  UserModule internal _userModule;
  RacingModule internal _racingModule;
  RandomModule internal _randomModule;

  constructor() {
    _userModule = new UserModule();
    _racingModule = new RacingModule();
    _randomModule = new RandomModule();

    singleton = new Singleton(address(_userModule), address(_racingModule), address(_randomModule));
  }

  function getContracts() external returns (Singleton, UserModule, RacingModule, RandomModule) {
    return (singleton, _userModule, _racingModule, _randomModule);
  }
}
