// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { SharedStorage } from "src/SharedStorage.sol";
import { RandomModule } from "src/Modules/RandomModule.sol";
import { UserModule } from "src/Modules/UserModule.sol";
import { RacingModule } from "src/Modules/RacingModule.sol";

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";

contract Singleton is SharedStorage, ERC20("Racing Tokens", "RACER", 18) {
  address internal racingModule;
  address internal userModule;
  address internal randomModule;

  constructor(address _userModule, address _racingModule, address _randomModule) {
    userModule = _userModule;
    racingModule = _racingModule;
    randomModule = _randomModule;
  }

  function addRacer(uint256 racerId, uint256 rarityValue, bytes32[] calldata proof) external {
    _executeModule(userModule, abi.encodeCall(UserModule.addRacer, (racerId, rarityValue, proof)));
  }

  function addMultiple(uint256[] calldata racerIds, uint256[] calldata rarityValues, bytes32[][] calldata proofs) external {
    if (racerIds.length != rarityValues.length) revert BadLength();
    if (racerIds.length != proofs.length) revert BadLength();

    _executeModule(userModule, abi.encodeCall(UserModule.addMultiple, (racerIds, rarityValues, proofs)));
  }

  function claimRacers() external {
    _executeModule(userModule, abi.encodeCall(UserModule.claimRacers, ()));
  }

  function getUserRacers(address user) external view returns (uint256[] memory) {
    bytes memory data = _staticModule(userModule, abi.encodeCall(UserModule.getUserRacers, (user)));
    return abi.decode(data, (uint256[]));
  }

  function resolveRaces(uint256 numberOfRaces) external returns (uint256) {
    uint256 randomSeed = _getRandomSeed();
    _executeModule(
      racingModule, abi.encodeCall(RacingModule.resolveRace, (numberOfRaces, randomSeed))
    );
  }

  function _getRandomSeed() internal returns (uint256) {
    bytes memory data = _executeModule(randomModule, abi.encodeCall(RandomModule.getRandomSeed, ()));
    return abi.decode(data, (uint256));
  }

  /*//////////////////////////////////////////////////////////////
                        ERC20 Functions
    //////////////////////////////////////////////////////////////*/
  function claimPoints() external {
    uint256 numberOfPoints = users[msg.sender].points;
    if (numberOfPoints == 0) revert IsZero();
    users[msg.sender].points = 0;
    _mint(msg.sender, numberOfPoints * decimals / 100);
  }

  /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

  function _executeModule(address module, bytes memory _data)
    private
    returns (bytes memory returnData)
  {
    bool success = true;
    (success, returnData) = module.delegatecall(_data);
    if (!success) {
      revert("Error Delegate Call");
    }
  }

  function _staticModule(address module, bytes memory _data)
    private
    view
    returns (bytes memory returnData)
  {
    bool success = true;
    (success, returnData) = module.staticcall(_data);
    if (!success) {
      revert("Error Static Call");
    }
  }
}
