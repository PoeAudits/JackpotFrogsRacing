// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct ProtocolFeeSpecs {
  uint256 protocolFeePercentage; // 1e18 = 100%
  address protocolFeeCollector;
}

struct BondingCurveSpecs {
  uint256 factor; // with precision of 1e18
  uint256 exponent;
  uint256 c; // constant; with precision of 1e18
}

struct CollectionSpecs {
  string name_;
  string symbol_;
  uint256 units_; // the amount of tokens that represent a single NFT
  string baseUri_; // leave blank if tokenURI is provided by a contract. If tokenUriProvider is provided, it will override this tokenUri
  address tokenUriContract_; // if provided, overrides the tokenUri
  uint256 maxNftSupply_; // the max supply in NFTs. 0 defaults to the max (CollectionImplementation::MAX_NFT_SUPPLY)
  bool useWhitelist_; // if enabled, only whitelisted addresses can mint. Must be set at init
  uint256 whitelistMintLimit_; // 0 for unlimited minting.
  bool isDeflationary_; // allows to burn from the bottom of the curve
}
