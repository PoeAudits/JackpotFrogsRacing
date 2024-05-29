// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { IDN404Mirror } from "src/Interfaces/IDN404Mirror.sol";
import { IDN404 } from "src/Interfaces/IDN404.sol";
import { StructuredLinkedList } from "src/Libraries/StructuredLinkedList.sol";
import { MerkleProofLib } from "lib/solmate/src/utils/MerkleProofLib.sol";
import { AccessControlUpgradeable } from
  "lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

contract JackpotFrogsRacing {
  using StructuredLinkedList for StructuredLinkedList.List;

  bytes32 internal constant root =
    0x8d7a4c26bddabe87ba66785e0b001a81ad781886e4576d1c5ecb8884b1238041;
  uint256 internal constant MAX_RACERS = 8;
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
    StructuredLinkedList.List raceList;
  }

  struct RaceInfo {
    uint64 nextRace;
    uint64 firstPendingRace;
    uint64 placeholder;
    uint64 placeholder2;
  }

  RaceInfo public raceInfo;

  mapping(uint256 => Racer) internal racers;
  mapping(uint256 => Race) internal races;
  mapping(uint256 => uint256) public points;
  mapping(address => uint32[]) internal userRacers;

  error CriticalError(string m);
  error NotOwner();
  error InvalidProof();
  error BadRace(uint256 id);
  error Overflow();

  constructor() {
    JACKPOT_CONTRACT.setSkipNFT(true);
  }

  function addRacer(uint256 racerId, uint256 rarityValue, bytes32[] calldata proof) external {
    if (JACKPOT_MIRROR.ownerOf(racerId) != msg.sender) revert NotOwner();

    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(racerId, rarityValue))));
    if (!MerkleProofLib.verify(proof, root, leaf)) revert InvalidProof();

    JACKPOT_MIRROR.transferFrom(msg.sender, address(this), racerId);

    uint32 _racerId = uint32(racerId);
    uint32 _rarityValue = uint32(rarityValue);

    RaceInfo storage info = raceInfo;
    Race storage jackpotRace = races[info.nextRace];

    racers[racerId] = Racer({ owner: msg.sender, id: _racerId, rarity: _rarityValue });

    userRacers[msg.sender].push(_racerId);
    jackpotRace.raceList.pushBack(racerId);

    unchecked {
      jackpotRace.raritySum += _rarityValue;
    }

    if (jackpotRace.raceList.size >= MAX_RACERS) {
      info.nextRace++;
    }
  }

  function startRace(uint256 maxRaces) external returns (bool) {
    RaceInfo storage info = raceInfo;
    uint256 startingRace = info.firstPendingRace;
    uint256 endRace = info.nextRace;
    uint256 numberOfRaces = endRace - startingRace;
    info.firstPendingRace = uint64(endRace);

    if (numberOfRaces > maxRaces) {
      numberOfRaces = maxRaces;
    }

    uint256 randomNumber = _getSeedRandomNumber();
    for (uint256 i; i < numberOfRaces; ++i) {
      _resolveRace(startingRace + i, randomNumber);
      randomNumber = uint256(_efficientHash(randomNumber));
    }
  }

  function _resolveRace(uint256 raceId, uint256 randomSeed) internal returns (uint256[] memory) {
    // Race storage race = races[raceId];
    // uint256 counter;
    // uint256 rareSum = race.raritySum;
    // randomSeed = _randomNumberFromSeed(randomSeed, rareSum);
    // (, uint256 racer) = race.raceList.getAdjacent(0, true);
    // uint256[] memory winners;
    // for (uint256 i; i < MAX_RACERS; ++i) {
    //     counter += racers[racer].rarity;
    //     if (counter >= randomSeed) {
    //         winners.push(racer);
    //         if (winners.length >= MAX_WINNERS) {
    //             return winners;
    //         }
    //         rareSum -= racers[racer].rarity;
    //         counter = 0;
    //         i = 0;
    //         randomSeed = _randomNumberFromSeed(randomSeed, rareSum);
    //         race.raceList.remove(racer);
    //         (, racer) = race.raceList.getAdjacent(0, true);
    //     } else {
    //         (, racer) = race.raceList.getAdjacent(racer, true);
    //     }
    // }
    // revert CriticalError("Bad Resolve Race");
  }

  function _randomNumberFromSeed(uint256 seed, uint256 maxValue) internal returns (uint256) {
    return uint256(_efficientHash(seed)) % maxValue;
  }

  function _getSeedRandomNumber() internal returns (uint256) {
    return 11234172934;
  }

  /*//////////////////////////////////////////////////////////////
                        Helper Functions
    //////////////////////////////////////////////////////////////*/
  function toUint32(uint256 x) internal pure returns (uint32) {
    if (x >= 1 << 32) revert Overflow();
    return uint32(x);
  }

  function toUint64(uint256 x) internal pure returns (uint64) {
    if (x >= 1 << 64) revert Overflow();
    return uint64(x);
  }

  function _efficientHash(uint256 a) internal pure returns (bytes32 value) {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x00, a)
      value := keccak256(0x00, 0x20)
    }
  }

  function onERC721Received(address, address, uint256, bytes memory)
    public
    virtual
    returns (bytes4)
  {
    return this.onERC721Received.selector;
  }
}
