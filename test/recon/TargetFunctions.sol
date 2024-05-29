// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BaseTargetFunctions } from "lib/chimera/src/BaseTargetFunctions.sol";
import { BeforeAfter } from "./BeforeAfter.sol";
import { Properties } from "./Properties.sol";
import { vm } from "lib/chimera/src/Hevm.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties, BeforeAfter {
// function counter_setNumber1(uint256 newNumber) public {
//     // example assertion test replicating testFuzz_SetNumber
//     try counter.setNumber(newNumber) {
//         if (newNumber != 0) {
//             t(counter.number() == newNumber, "number != newNumber");
//         }
//     } catch {
//         t(false, "setNumber reverts");
//     }
// }

    function addRacer(uint256 racerId, uint256 rarityValue) public {
        racerId = (racerId % 77000) + 1;
        rarityValue = (rarityValue % 1000000000) + 1;
        bytes32[] memory proof;
        target.addRacer(racerId, rarityValue, proof);
    }
    function addMultiple(uint256 racerId, uint256 rarityValue) public {
        racerId = (racerId % 77000) + 1;
        rarityValue = (rarityValue % 1000000000) + 1;
        bytes32[] memory proof;
        target.addRacer(racerId, rarityValue, proof);
    }
}
