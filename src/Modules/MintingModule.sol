// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { SharedStorage } from "src/SharedStorage.sol";
import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";

contract MintingModule is SharedStorage, ERC20 {
  address public immutable owner;

  constructor() ERC20("Racing Tokens", "RACER", 18) {
    owner = msg.sender;
  }

  function mint(address to, uint256 amount) external {
    require(msg.sender == owner, "Not Owner");
    _mint(to, amount);
  }
}
