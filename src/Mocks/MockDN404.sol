// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// DN404
import "src/Ref/DN404.sol";

contract MockDN404 is DN404 {
  /**
   *
   * Constructur & Initializer *
   *
   */

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(address _mirror) {
    _initializeDN404(0, address(0), _mirror);
  }

  /**
   *
   * Mint & Burn Functions *
   *
   */
  function _mintMultipleTo(address to, uint256 nftAmount) internal {
    uint256 amount = nftAmount * _unit();
    _mint(to, amount);
  }

  /**
   *
   * Buy and Sell  *
   *
   */
  function buy(uint256 nftAmount) external payable {
    require(nftAmount > 0, "CollectionImpl: amount must be > 0");
    // mint the nfts to the user
    _mintMultipleTo(msg.sender, nftAmount);
  }

  /**
   *
   * Other *
   *
   */
  function name() public view virtual override returns (string memory) {
    return "MockFrogs";
  }

  function symbol() public view virtual override returns (string memory) {
    return "MF";
  }

  function _tokenURI(uint256 id) internal view virtual override returns (string memory) {
    return "No Token Uri";
  }
}
