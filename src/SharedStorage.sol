// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { IDN404Mirror } from "src/Interfaces/IDN404Mirror.sol";
import { IDN404 } from "src/Interfaces/IDN404.sol";
// import {StructuredLinkedList} from "src/Libraries/StructuredLinkedList.sol";

abstract contract SharedStorage {
  bytes32 internal constant root =
    0x8d7a4c26bddabe87ba66785e0b001a81ad781886e4576d1c5ecb8884b1238041;
  uint256 public constant MAX_RACERS = 8;
  uint256 internal constant MAX_WINNERS = 4;

  IDN404Mirror internal constant JACKPOT_MIRROR =
    IDN404Mirror(0xd943bf648A5B6066A93A690D056a0D2a218b0cDf);
  IDN404 internal constant JACKPOT_CONTRACT = IDN404(0x429530eB56f032a7aa87f7E6aef5C5DC206e041f);

  struct Racer {
    address owner;
    uint32 id;
    uint32 rarity;
  }

  struct Race {
    uint32 raritySum;
    Racer[] racers;
  }

  struct User {
    uint32[] userRacers;
    uint32 points;
  }

  uint256 public nextRace;
  uint256 public firstPendingRace;

  mapping(uint256 => Racer) public racers;
  mapping(uint256 => Race) public races;
  mapping(address => User) public users;
  // mapping(address => uint256) public points;
  // mapping(address => uint256) internal userBalance;
  // mapping(address => uint32[]) internal userRacers;

  event DEBUG(string s, uint256 v);
  event DEBUG(string s, address a);

  error CriticalError(string m);
  error NotOwner();
  error InvalidProof();
  error BadRace(uint256 id);
  error Overflow();
  error IsZero();
  error BadLength();
}
