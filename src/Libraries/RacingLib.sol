// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { StructuredLinkedList } from "src/Libraries/StructuredLinkedList.sol";

library RacingLib {
  using StructuredLinkedList for StructuredLinkedList.List;

  uint256 constant MAX_RACERS = 8;
  uint256 constant MAX_WINNERS = 4;

  error NonFullRace();

  struct Racer {
    address owner;
    uint32 id;
    uint32 rarity;
  }

  struct Race {
    uint32 raritySum;
    StructuredLinkedList.List racers;
  }

  function commenceRace(Race storage self, uint256 randomNumber)
    internal
    returns (uint256[] memory)
  {
    uint256[] memory winners;
    uint256 currentRandom = randomNumber;
    for (uint256 i; i < MAX_WINNERS; ++i) { }

    return winners;
  }

  function _selectWinner(StructuredLinkedList.List storage list, uint256 randomNumber)
    private
    returns (uint256)
  {
    if (list.size != MAX_RACERS) revert NonFullRace();
    (, uint256 head) = list.getAdjacent(0, true);
    uint256 sum;

    for (uint256 i; i < MAX_RACERS; ++i) { }
  }

  function _efficientHash(uint256 a) internal pure returns (bytes32 value) {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x00, a)
      value := keccak256(0x00, 0x20)
    }
  }
}
