// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { IDN404Mirror } from "src/Interfaces/IDN404Mirror.sol";
import { IDN404 } from "src/Interfaces/IDN404.sol";
import { MerkleProofLib } from "lib/solmate/src/utils/MerkleProofLib.sol";
// import {AccessControlUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

contract JackpotFrogsRacing {
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
    Racer[] racers;
  }

  uint256 nextRace;
  uint256 firstPendingRace;

  mapping(uint256 => Racer) public racers;
  mapping(uint256 => Race) public races;
  mapping(address => Racer[]) public userRacers;

  event DEBUG(string s, uint256 v);
  event DEBUG(string s, address a);
  event DEBUG(string s, Racer r);

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

    Race storage jackpotRace = races[nextRace];

    jackpotRace.racers.push(Racer({ owner: msg.sender, id: _racerId, rarity: _rarityValue }));

    unchecked {
      jackpotRace.raritySum += _rarityValue;
    }

    if (jackpotRace.racers.length >= MAX_RACERS) {
      nextRace++;
    }
  }

  function beginRace(uint256 maxRaces) external {
    uint256 numberOfRaces = nextRace - firstPendingRace;
    uint256 startRace = firstPendingRace;
    if (numberOfRaces > maxRaces) {
      numberOfRaces = maxRaces;
    }
    firstPendingRace += numberOfRaces;

    uint256 randomNumber = _getSeedRandomNumber();
    for (uint256 i; i < numberOfRaces; ++i) {
      _resolveRace(races[startRace + i], randomNumber);
      randomNumber = uint256(_efficientHash(randomNumber));
    }
  }

  function _resolveRace(Race memory race, uint256 randomSeed) internal {
    uint256 cumulativeSum;
    uint256 raritySum = race.raritySum;
    for (uint256 i; i < MAX_WINNERS; ++i) {
      uint256 winnerIndex = _pickWinner(race.racers, randomSeed);
      emit DEBUG("Winner Racer: ", race.racers[winnerIndex]);

      if (winnerIndex != MAX_RACERS - i) {
        Racer memory temp = race.racers[MAX_RACERS - i - 1];
        race.racers[MAX_RACERS - i - 1] = race.racers[winnerIndex];
        race.racers[winnerIndex] = temp;
      }

      randomSeed = _randomNumberFromSeed(randomSeed, raritySum);
      cumulativeSum = 0;
    }
    _recordWinners(race.racers);
  }

  function _pickWinner(Racer[] memory currentRacers, uint256 randomSeed) internal returns (uint256) {
    uint256 cumulativeSum;
    for (uint256 i; i < MAX_RACERS; ++i) {
      cumulativeSum += currentRacers[i].rarity;
      if (cumulativeSum > randomSeed) {
        return i;
      }
    }
  }

  function _recordWinners(Racer[] memory results) internal {
    userRacers[results[MAX_RACERS - 1].owner].push(results[MAX_RACERS - 1]);
    userRacers[results[MAX_RACERS - 2].owner].push(results[MAX_RACERS - 2]);
    userRacers[results[MAX_RACERS - 3].owner].push(results[MAX_RACERS - 3]);
    userRacers[results[MAX_RACERS - 4].owner].push(results[MAX_RACERS - 4]);

    userRacers[results[MAX_RACERS - 1].owner].push(results[MAX_RACERS - 5]);
    userRacers[results[MAX_RACERS - 1].owner].push(results[MAX_RACERS - 6]);
    userRacers[results[MAX_RACERS - 2].owner].push(results[MAX_RACERS - 7]);

    userRacers[msg.sender].push(results[MAX_RACERS - 8]);
  }

  function _randomNumberFromSeed(uint256 seed, uint256 maxValue) internal returns (uint256) {
    return uint256(_efficientHash(seed)) % maxValue;
  }

  function _getSeedRandomNumber() internal returns (uint256) {
    return 112342934;
  }

  function getUserRacers(address user) external view returns (uint256[] memory) {
    uint256 len = userRacers[user].length;
    uint256[] memory r = new uint256[](len);

    for (uint256 i; i < len; ++i) {
      r[i] = userRacers[user][i].id;
    }

    return r;
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
