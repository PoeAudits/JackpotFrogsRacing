// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ITokenUri {
  function tokenURI(uint256 tokenId, address collection) external view returns (string memory);
}
