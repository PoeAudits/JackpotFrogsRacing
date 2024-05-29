// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Own Interfaces
import "src/Ref/Structs.sol";

interface IRouter {
  function protocolFeeSpecs() external view returns (ProtocolFeeSpecs memory);
}
