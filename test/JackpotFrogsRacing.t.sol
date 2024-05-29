//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/forge-std/src/Test.sol";
import "src/JackpotFrogsHarness.sol";

import { IDN404Mirror } from "src/Interfaces/IDN404Mirror.sol";
import { IDN404 } from "src/Interfaces/IDN404.sol";

contract JackpotFrogsTest is Test {
  JackpotFrogsHarness public target;

  IDN404Mirror internal constant JACKPOT_MIRROR =
    IDN404Mirror(0xd943bf648A5B6066A93A690D056a0D2a218b0cDf);
  IDN404 internal constant JACKPOT_CONTRACT = IDN404(0x429530eB56f032a7aa87f7E6aef5C5DC206e041f);

  string private checkpointLabel;
  uint256 private checkpointGasLeft = 1; // Start the slot warm.

  address public admin = address(99999);
  address public alice = address(5000);
  address public bob = address(7000);
  address public carl = address(9000);

  struct racerInfo {
    uint256 id;
    uint256 rarity;
  }

  function setUp() public {
    vm.createSelectFork("localhost");
    target = new JackpotFrogsHarness();

    buyFrogs(alice, 4);
    buyFrogs(bob, 4);
    buyFrogs(carl, 4);
  }

  function testRacing() public {
    racerInfo[] memory racers = getRacerInfo();
    bytes32[] memory pseudoProof = new bytes32[](1);
    pseudoProof[0] = keccak256(abi.encode("Nothing"));

    vm.startPrank(alice);
    for (uint256 i; i < 4; ++i) {
      JACKPOT_MIRROR.approve(address(target), racers[i].id);
    }
    target.addRacer(racers[0].id, racers[0].rarity, pseudoProof);
    target.addRacer(racers[1].id, racers[1].rarity, pseudoProof);
    target.addRacer(racers[2].id, racers[2].rarity, pseudoProof);
    target.addRacer(racers[3].id, racers[3].rarity, pseudoProof);
    vm.stopPrank();

    console2.log("There");
    vm.startPrank(bob);
    for (uint256 i; i < 4; ++i) {
      JACKPOT_MIRROR.approve(address(target), racers[i + 4].id);
    }
    target.addRacer(racers[4].id, racers[4].rarity, pseudoProof);
    target.addRacer(racers[5].id, racers[5].rarity, pseudoProof);
    target.addRacer(racers[6].id, racers[6].rarity, pseudoProof);
    target.addRacer(racers[7].id, racers[7].rarity, pseudoProof);
    vm.stopPrank();

    vm.startPrank(carl);
    for (uint256 i; i < 2; ++i) {
      JACKPOT_MIRROR.approve(address(target), racers[i + 8].id);
    }
    target.addRacer(racers[8].id, racers[8].rarity, pseudoProof);
    target.addRacer(racers[9].id, racers[9].rarity, pseudoProof);
    vm.stopPrank();

    vm.prank(admin);
    target.beginRace(5);
    uint256[] memory aliceRacers = target.getUserRacers(alice);
    uint256[] memory bobRacers = target.getUserRacers(bob);
    uint256[] memory adminRacers = target.getUserRacers(admin);
  }

  function buyFrogs(address caller, uint256 amount) public {
    hoax(caller, 1e14 * amount);
    address(JACKPOT_CONTRACT).call{ value: 1e14 * amount }(
      abi.encodeWithSignature("buy(uint256,uint256)", amount, type(uint256).max)
    );
  }

  function testProof() public {
    uint256 racerId = 1400;
    uint256 rarity = 223075;
    bytes32[] memory proof = new bytes32[](17);
    proof[0] = (0x2df06080669d0b3228b2ff0de67a4c72f61fdb85ae36a73427c84c46b96f0223);
    proof[1] = (0xcd895d597628a93309adda961923c98a49d7a8feb9bada25eb9673fccd5280d9);
    proof[2] = (0xd2c359ef1354681b56ca3c7e50ee924ff2aabb5e2b3aa53437571340f9c7ea6e);
    proof[3] = (0xec7fc61e6bf508e41127a1cd713cfe0e46e332a20e0a0ac005cb063138ab1978);
    proof[4] = (0x0e48e79e3a2da3911263982ccb0708e4b63b70b943dad1ab8c33933456ad7259);
    proof[5] = (0x413f567f5b804ee0987e806c61397cb829b12c8f1a7af24d1ecd1735bb46a931);
    proof[6] = (0xe98f835e770f6dc2d03957cb32ccf11d0ba79a37bb4eb24ab04f1673a976c071);
    proof[7] = (0xdd46718d78c5d7460eda88712b50648b73a04bdca9510ea3666b9f7fb5810236);
    proof[8] = (0xd216cf49401349d7b358179d0bf053e4fcb5ffea795034026bf74fd9e582cb13);
    proof[9] = (0x498b62930d5ed7630581180f895715145b21ab41a37b6c4e4f1b3a5f9f73e325);
    proof[10] = (0x053d831957d6f0f897b03d8402ea69f975d8e87c1de0e01a68397b618b787ab9);
    proof[11] = (0x3c103309f5bd2bd5205b7cc6fafa2b5ab1bd12e3af25620c36f2980c3974d500);
    proof[12] = (0xeb21047ee5706bd5dd8f4e3a3b87beaef7e6876c1ddfd0c421373b40875acc65);
    proof[13] = (0x0798170821b25a20113d16d355a831e01d760ae3120c206c04c6c1afd97567e9);
    proof[14] = (0x9d24df516101562f43db31663bc0507b4691bda2f6616ea89843ffced40c02a6);
    proof[15] = (0x924b5132d4465c2da686a2d4e82e9a56d66bdc6958787752c2cfb6ea3e0491ff);
    proof[16] = (0x13401a2e7a2a2101ae5874ee28d4f8c1d3b39df4c0aec9670a22a914d693b326);

    assertTrue(target.TryProof(racerId, rarity, proof));

    proof[6] = 0xe98f835e770f6dc2d03957cb32ccf11d0ba79a37bb4eb24ab04f1673a976c072; // ending 1 -> 2

    assertFalse(target.TryProof(racerId, rarity, proof));
  }

  function testKeccak(uint256 input) public {
    assertEq(_efficientHash(input), _efficientHashCheck(input));
  }

  function _efficientHash(uint256 a) internal pure returns (bytes32 value) {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x00, a)
      value := keccak256(0x00, 0x20)
    }
  }

  function _efficientHashCheck(uint256 a) internal pure returns (bytes32 value) {
    return keccak256(abi.encode(a));
  }

  /*//////////////////////////////////////////////////////////////
                             Gas Functions
    //////////////////////////////////////////////////////////////*/

  function startMeasuringGas(string memory label) internal virtual {
    checkpointLabel = label;

    checkpointGasLeft = gasleft();
  }

  function stopMeasuringGas() internal virtual {
    uint256 checkpointGasLeft2 = gasleft();

    // Subtract 100 to account for the warm SLOAD in startMeasuringGas.
    uint256 gasDelta = checkpointGasLeft - checkpointGasLeft2 - 100;

    emit log_named_uint(string(abi.encodePacked(checkpointLabel, " Gas")), gasDelta);
  }

  function getRacerInfo() internal returns (racerInfo[] memory) {
    racerInfo[] memory racers = new racerInfo[](10);
    racers[0] = racerInfo({ id: 16095, rarity: 231982 });
    racers[1] = racerInfo({ id: 16096, rarity: 110729 });
    racers[2] = racerInfo({ id: 16097, rarity: 470584 });
    racers[3] = racerInfo({ id: 16098, rarity: 646226 });
    racers[4] = racerInfo({ id: 16099, rarity: 708926 });
    racers[5] = racerInfo({ id: 16100, rarity: 143172 });
    racers[6] = racerInfo({ id: 16101, rarity: 108263 });
    racers[7] = racerInfo({ id: 16102, rarity: 114827 });
    racers[8] = racerInfo({ id: 16103, rarity: 1495096 });
    racers[9] = racerInfo({ id: 16104, rarity: 249504 });

    return racers;
  }
}
