// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { Setup } from "./Setup.sol";

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Setup {
  struct Vars {
    uint256 placeholder;
  }

  Vars internal _before;
  Vars internal _after;

  // _before.placeholder = target.placeholder();
  function __before() internal { }

  // _after.placeholder = target.placeholder();
  function __after() internal { }
}
