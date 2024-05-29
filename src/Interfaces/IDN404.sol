// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IDN404 {
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function balanceOf(address owner) external view returns (uint256);
  function decimals() external pure returns (uint8);
  function getSkipNFT(address owner) external view returns (bool);
  function mirrorERC721() external view returns (address);
  function name() external view returns (string memory);
  function setSkipNFT(bool skipNFT) external returns (bool);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  // NOT STANDARD
  function units() external returns (uint256);
}
