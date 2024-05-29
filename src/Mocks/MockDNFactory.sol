// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { MockDN404 } from "src/Mocks/MockDN404.sol";
import { MockDN404Mirror } from "src/Mocks/MockDN404Mirror.sol";

contract MockDNFactory {
  MockDN404 public mockFrog;
  MockDN404Mirror public mockFrogMirror;

  constructor() {
    mockFrogMirror = new MockDN404Mirror();
    mockFrog = new MockDN404(address(mockFrogMirror));
  }

  function getContracts() external view returns (MockDN404, MockDN404Mirror) {
    return (mockFrog, mockFrogMirror);
  }
}
