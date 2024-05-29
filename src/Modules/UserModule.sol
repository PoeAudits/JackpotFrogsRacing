// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { SharedStorage } from "src/SharedStorage.sol";
import { MerkleProofLib } from "lib/solmate/src/utils/MerkleProofLib.sol";

contract UserModule is SharedStorage {

  function addRacer(uint256 racerId, uint256 rarityValue, bytes32[] calldata proof) external {
    if (JACKPOT_MIRROR.ownerOf(racerId) != msg.sender) revert NotOwner();


    verifyProof(proof, keccak256(bytes.concat(keccak256(abi.encode(racerId, rarityValue)))));

    JACKPOT_MIRROR.transferFrom(msg.sender, address(this), racerId);

    uint32 _racerId = uint32(racerId);
    uint32 _rarityValue = uint32(rarityValue);

    Race storage jackpotRace = races[nextRace];

    jackpotRace.racers.push(Racer({ owner: msg.sender, id: _racerId, rarity: _rarityValue }));

    unchecked {
      jackpotRace.raritySum += _rarityValue;
    }

    while (races[nextRace].racers.length >= MAX_RACERS) {
        nextRace++;
    }
  }

  function addMultiple(uint256[] calldata racerIds, uint256[] calldata rarityValues, bytes32[][] calldata proofs) external {
    uint256 len = racerIds.length;
    for (uint256 i; i < len; ++i) {
      if (JACKPOT_MIRROR.ownerOf(racerIds[i]) != msg.sender) revert NotOwner();

      verifyProof(proofs[i], keccak256(bytes.concat(keccak256(abi.encode(racerIds[i], rarityValues[i])))));

      JACKPOT_MIRROR.transferFrom(msg.sender, address(this), racerIds[i]);

      uint32 _racerId = uint32(racerIds[i]);
      uint32 _rarityValue = uint32(rarityValues[i]);

      races[nextRace + i].racers.push(Racer({owner: msg.sender, id: _racerId, rarity: _rarityValue}));

      unchecked {
        races[nextRace + i].raritySum += _rarityValue;
      }
    }

    while (races[nextRace].racers.length >= MAX_RACERS) {
        nextRace++;
    }

  }

  function verifyProof(bytes32[] calldata proof, bytes32 leaf) private pure {
    // if (!MerkleProofLib.verify(proof, root, leaf)) revert InvalidProof();
  }

  function claimRacers() external {
    address user = msg.sender;
    uint256 len = users[user].userRacers.length;
    if (len == 0) revert IsZero();

    for (uint256 i; i < len; ++i) {
      uint32 id = users[user].userRacers[len - i - 1];
      users[user].userRacers.pop();
      JACKPOT_MIRROR.safeTransferFrom(address(this), user, id);
    }
  }

  function getUserRacers(address user) external view returns (uint256[] memory) {
    uint256 len = users[user].userRacers.length;
    uint256[] memory r = new uint256[](len);

    for (uint256 i; i < len; ++i) {
      r[i] = users[user].userRacers[i];
    }

    return r;
  }

  function _efficientHash(uint256 a) internal pure returns (bytes32 value) {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x00, a)
      value := keccak256(0x00, 0x20)
    }
  }
}
