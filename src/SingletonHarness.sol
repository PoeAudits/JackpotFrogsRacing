// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/Singleton.sol";
import { MerkleProofLib } from "lib/solmate/src/utils/MerkleProofLib.sol";

contract SingletonHarness is Singleton {
  constructor(address _userModule, address _racingModule, address _randomModule)
    Singleton(_userModule, _racingModule, _randomModule)
  { }

  function TryProof(uint256 racerId, uint256 rarity, bytes32[] calldata proof)
    external
    pure
    returns (bool)
  {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(racerId, rarity))));
    return MerkleProofLib.verify(proof, root, leaf);
  }

  function addRacerNoProof(uint256 racerId, uint256 rarityValue) external {
    if (JACKPOT_MIRROR.ownerOf(racerId) != msg.sender) revert NotOwner();

    JACKPOT_MIRROR.transferFrom(msg.sender, address(this), racerId);

    uint32 _racerId = uint32(racerId);
    uint32 _rarityValue = uint32(rarityValue);

    Race storage jackpotRace = races[nextRace];

    jackpotRace.racers.push(Racer({ owner: msg.sender, id: _racerId, rarity: _rarityValue }));

    unchecked {
      jackpotRace.raritySum += _rarityValue;
    }

    if (jackpotRace.racers.length >= MAX_RACERS) {
      nextRace++;
    }
  }
}
