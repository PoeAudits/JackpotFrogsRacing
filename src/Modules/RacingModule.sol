// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { SharedStorage } from "src/SharedStorage.sol";

contract RacingModule is SharedStorage {
  function resolveRace(uint256 raceId, uint256 randomSeed) external {
    Race storage race = races[raceId];
    uint256 raritySum = race.raritySum;
    for (uint256 i; i < MAX_WINNERS; ++i) {
      randomSeed = _randomNumberFromSeed(randomSeed, raritySum);
      uint256 winnerIndex = _pickWinner(race.racers, randomSeed);
      if (winnerIndex != MAX_RACERS - i) {
        Racer memory temp = race.racers[MAX_RACERS - i - 1];
        race.racers[MAX_RACERS - i - 1] = race.racers[winnerIndex];
        race.racers[winnerIndex] = temp;
      }
    }
  }

  function _pickWinner(Racer[] memory currentRacers, uint256 randomSeed)
    internal
    pure
    returns (uint256)
  {
    uint256 cumulativeSum;
    for (uint256 i; i < MAX_RACERS; ++i) {
      cumulativeSum += currentRacers[i].rarity;
      if (cumulativeSum > randomSeed) {
        return i;
      }
    }
    return MAX_RACERS;
  }

  function _recordWinners(Racer[] memory results) private {
    for (uint256 i = MAX_RACERS - 1; i > 1; --i) {
      Racer memory racer = results[i];
      users[racer.owner].userRacers.push(racer.id);
      users[racer.owner].points += uint32(i * 100);
    }

    users[msg.sender].userRacers.push(results[0].id);
    users[msg.sender].userRacers.push(results[1].id);
  }

  function _efficientHash(uint256 a) internal pure returns (bytes32 value) {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x00, a)
      value := keccak256(0x00, 0x20)
    }
  }

  function _randomNumberFromSeed(uint256 seed, uint256 maxValue) private pure returns (uint256) {
    return uint256(_efficientHash(seed)) % maxValue;
  }
}
