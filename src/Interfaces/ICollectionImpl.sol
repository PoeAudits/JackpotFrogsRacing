// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "src/Interfaces/IBlastPoints.sol";
import "src/Ref/Structs.sol";

interface ICollectionImpl {
  /**
   *
   * Structs *
   *
   */
  struct InitializeParams {
    /* erc721 */
    CollectionSpecs collectionSpecs;
    address tokenUriFallbackContract;
    /* bonding curve */
    BondingCurveSpecs bondingCurveSpecs;
    /* shared ownership */
    address creatorVault;
    /* roles */
    address creator;
    address router;
    /* blast */
    address gasClaimer;
    address yieldClaimer;
    address pointsOperator;
    IBlastPoints blastPoints;
    /* dn404 */
    address dn404Mirror;
  }

  function initialize(InitializeParams memory params) external;
}
