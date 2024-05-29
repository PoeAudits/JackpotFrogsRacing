// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "src/Ref/DN404Mirror.sol";

contract MockDN404Mirror is DN404Mirror(msg.sender) { }
