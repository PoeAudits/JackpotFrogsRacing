// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

contract RandomModule {
  function getRandomSeed() external pure returns (uint256) {
    return 112342934;
  }

  function _efficientHash(uint256 a) internal pure returns (bytes32 value) {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x00, a)
      value := keccak256(0x00, 0x20)
    }
  }
}
