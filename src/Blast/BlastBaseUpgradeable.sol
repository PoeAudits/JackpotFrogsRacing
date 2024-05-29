// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import { IBlast } from "src/Interfaces/IBlast.sol";
import { IBlastPoints } from "src/Interfaces/IBlastPoints.sol";

/**
 * @title BlastBaseUpgradeable
 * @notice Blast documentation:
 * Gas fees:
 * https://docs.blast.io/building/guides/gas-fees
 * Yield:
 * https://docs.blast.io/building/guides/eth-yield
 * Points:
 * https://docs.blast.io/airdrop/api
 */
contract BlastBaseUpgradeable is Initializable {
  IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);

  address public gasClaimer;
  address public yieldClaimer;

  IBlastPoints public blastPoints;
  address public pointsOperator;

  modifier onlyGasClaimer() {
    require(msg.sender == gasClaimer, "BlastBaseUpgradeable: caller is not the gasClaimer");
    _;
  }

  modifier onlyYieldClaimer() {
    require(msg.sender == yieldClaimer, "BlastBaseUpgradeable: caller is not the yieldClaimer");
    _;
  }

  modifier onlyPointsOperator() {
    require(msg.sender == pointsOperator, "BlastBaseUpgradeable: caller is not the pointsOperator");
    _;
  }

  function __BlastBase_init(
    address _gasClaimer,
    address _yieldClaimer,
    IBlastPoints _blastPoints,
    address _pointsOperator
  ) internal onlyInitializing {
    gasClaimer = _gasClaimer;
    yieldClaimer = _yieldClaimer;

    BLAST.configureClaimableGas();
    BLAST.configureClaimableYield();

    blastPoints = _blastPoints;
    pointsOperator = _pointsOperator;

    blastPoints.configurePointsOperator(_pointsOperator);
  }

  /**
   *
   * Gas *
   *
   */
  function claimAllGas(address recipientOfGas) external onlyGasClaimer returns (uint256) {
    return BLAST.claimAllGas(address(this), recipientOfGas);
  }

  function claimGasAtMinClaimRate(address recipientOfGas, uint256 minClaimRateBips)
    external
    onlyGasClaimer
    returns (uint256)
  {
    return BLAST.claimGasAtMinClaimRate(address(this), recipientOfGas, minClaimRateBips);
  }

  function claimMaxGas(address recipientOfGas) external onlyGasClaimer returns (uint256) {
    return BLAST.claimMaxGas(address(this), recipientOfGas);
  }

  function claimGas(address recipientOfGas, uint256 gasToClaim, uint256 gasSecondsToConsume)
    external
    onlyGasClaimer
    returns (uint256)
  {
    return BLAST.claimGas(address(this), recipientOfGas, gasToClaim, gasSecondsToConsume);
  }

  function setGasClaimer(address gasClaimer_) external onlyGasClaimer {
    gasClaimer = gasClaimer_;
  }

  /**
   *
   * Yield *
   *
   */
  function claimAllYield(address recipientOfYield) external onlyYieldClaimer returns (uint256) {
    return BLAST.claimAllYield(address(this), recipientOfYield);
  }

  function claimYield(address recipientOfYield, uint256 amount)
    external
    onlyYieldClaimer
    returns (uint256)
  {
    return BLAST.claimYield(address(this), recipientOfYield, amount);
  }

  function setYieldClaimer(address yieldClaimer_) external onlyYieldClaimer {
    yieldClaimer = yieldClaimer_;
  }

  /**
   *
   * Points *
   *
   */

  /// @dev The current points operator must set the new points operator on the blastPoints contract directly with the
  /// function onfigurePointsOperatorOnBehalf(address contractAddress, address operatorAddress).
  function setPointsOperator(address pointsOperator_) external onlyPointsOperator {
    pointsOperator = pointsOperator_;
  }

  function setBlastPoints(IBlastPoints blastPoints_) external onlyPointsOperator {
    blastPoints = blastPoints_;

    blastPoints.configurePointsOperator(pointsOperator);
  }
}
