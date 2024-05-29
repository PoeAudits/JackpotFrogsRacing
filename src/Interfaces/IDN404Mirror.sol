// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IDN404Mirror {
  function approve(address spender, uint256 id) external payable;
  function balanceOf(address nftOwner) external view returns (uint256);
  function baseERC20() external view returns (address base);
  function getApproved(uint256 id) external view returns (address);
  function isApprovedForAll(address nftOwner, address operator) external view returns (bool);
  function name() external view returns (string memory);
  function owner() external view returns (address);
  function ownerAt(uint256 id) external view returns (address);
  function ownerOf(uint256 id) external view returns (address);
  function pullOwner() external returns (bool);
  function safeTransferFrom(address from, address to, uint256 id) external payable;
  function safeTransferFrom(address from, address to, uint256 id, bytes memory data)
    external
    payable;
  function setApprovalForAll(address operator, bool approved) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool result);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 id) external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function transferFrom(address from, address to, uint256 id) external payable;
}
