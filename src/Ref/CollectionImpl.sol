// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// OpenZeppelin
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

// DN404
import "./DN404.sol";

// Own Interfaces
import "src/Interfaces/ICollectionImpl.sol";
import "src/Interfaces/ITokenUri.sol";
import "src/Interfaces/IRouter.sol";

// Blast
import "src/Blast/BlastBaseUpgradeable.sol";

contract CollectionImplementation is
  Initializable,
  DN404,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  BlastBaseUpgradeable,
  ICollectionImpl
{
  using Strings for uint256;

  /**
   *
   * Events *
   *
   */
  event PaymentReceived(address from, uint256 amount);
  event Buy(
    address indexed buyer, uint256 amount, uint256 price, uint256 protocolFee, uint256 creatorFee
  );
  event Sell(
    address indexed seller, uint256 amount, uint256 price, uint256 protocolFee, uint256 creatorFee
  );

  event DeflationarySell(
    address indexed seller, uint256 amount, uint256 price, uint256 protocolFee, uint256 creatorFee
  );

  event CreatorFeePercentageChanged(uint256 newCreatorFeePercentage);
  event CreatorFeeFrozen();
  event BaseUriChanged(string newBaseUri);
  event TokenUriContractChanged(address newTokenUriContract);
  event MetadataFrozen();
  event WhitelistDisabled();
  event WhitelistModified(address[] addresses, bool isWhitelisted);
  event WhitelistMintLimitChanged(uint256 newWhitelistMintLimit);

  /**
   *
   * Constants *
   *
   */
  uint256 public constant MAX_NAME_LENGTH = 30;
  uint256 public constant MAX_SYMBOL_LENGTH = 10;
  // limited by dn404
  uint256 public constant MAX_NFT_SUPPLY = 2 ** 32 - 2;
  uint256 public constant MAX_UNITS = 100_000 ether;

  /**
   *
   * Immutable State (set at init)*
   *
   */

  /* Bonding Curve */
  BondingCurveSpecs public bondingCurveSpecs;

  /* Shared Ownership */
  address payable public creatorVault;

  /* Roles */
  address public router;

  /* DN404 */
  uint256 public units;

  /**
   *
   * Mutable State *
   *
   */
  string private _name;
  string private _symbol;

  /* ERC721 */
  string public baseUri;
  address public tokenUriContract;
  address public tokenUriFallbackContract;

  // supply limit. MAX_NFT_SUPPLY * _uint() is the maximum value for maxSupply
  uint256 public maxSupply;

  /* Whitelist */
  // if enabled, only whitelisted addresses can mint. Must be set at init
  bool public isWhitelistEnabled;
  mapping(address => bool) public whitelist;
  uint256 public whitelistMintLimit;
  mapping(address => uint256) public whitelistMinted;

  /**
   * @dev We track how much supply is on the bonding curve for a given collection.
   * This is not always equal to the total supply of the collection,
   * because some tokens may have been burned.
   */
  uint256 public bondingCurveSupply;

  bool public metadataFreeze;
  bool public bondingCurveFreeze;

  uint256 public creatorFeePercentage; // 1e18 = 100%

  // deflationary bonding curve
  bool public isDeflationary;
  uint256 public deflationBurnCount;

  /**
   *
   * Constructur & Initializer *
   *
   */

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(InitializeParams memory params) public override initializer {
    uint256 nameLength = _utfStringLength(params.collectionSpecs.name_);
    require(nameLength > 0 && nameLength <= MAX_NAME_LENGTH, "Invalid name length");
    uint256 symbolLength = _utfStringLength(params.collectionSpecs.symbol_);
    require(symbolLength > 0 && symbolLength <= MAX_SYMBOL_LENGTH, "Invalid symbol length");

    /* name & symbol */
    _name = params.collectionSpecs.name_;
    _symbol = params.collectionSpecs.symbol_;

    /* DN404 */
    require(
      params.collectionSpecs.units_ > 0 && params.collectionSpecs.units_ <= MAX_UNITS,
      "CollectionImpl: invalid units"
    );
    units = params.collectionSpecs.units_;

    /* Other */
    __Ownable_init(params.creator);
    __BlastBase_init(params.gasClaimer, params.creator, params.blastPoints, params.pointsOperator);
    __ReentrancyGuard_init();

    /* DN404 */
    _initializeDN404(0, address(0), params.dn404Mirror);

    /* erc721 */
    baseUri = params.collectionSpecs.baseUri_;
    tokenUriContract = params.collectionSpecs.tokenUriContract_;
    tokenUriFallbackContract = params.tokenUriFallbackContract;

    /* bonding curve */
    bondingCurveSpecs = params.bondingCurveSpecs;

    /* shared ownership */
    creatorVault = payable(params.creatorVault);

    /* roles */
    router = params.router;

    creatorFeePercentage = 0.05 * 1e18; // 5%

    if (params.collectionSpecs.maxNftSupply_ > 0) {
      require(
        params.collectionSpecs.maxNftSupply_ <= MAX_NFT_SUPPLY, "CollectionImpl: maxSupply too high"
      );
      maxSupply = params.collectionSpecs.maxNftSupply_ * _unit();
    } else {
      maxSupply = MAX_NFT_SUPPLY * _unit();
    }

    isWhitelistEnabled = params.collectionSpecs.useWhitelist_;
    whitelistMintLimit = params.collectionSpecs.whitelistMintLimit_;

    isDeflationary = params.collectionSpecs.isDeflationary_;
  }

  /**
   *
   * Mint & Burn Functions *
   *
   */
  function _mintMultipleTo(address to, uint256 nftAmount) internal {
    uint256 amount = nftAmount * _unit();
    require(
      totalSupply() + deflationBurnCount * _unit() + amount <= maxSupply,
      "CollectionImpl: max supply reached"
    );

    _mint(to, amount);
  }

  function _bondingCurveBurnMultiple(uint256[] memory tokenIds_) internal {
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      uint256 tokenId = tokenIds_[i];
      address owner = _ownerOf(tokenIds_[i]);
      // to burn specific NFTs, we need to transfer them to this contract first (due to dn404)
      _initiateTransferFromNFT(owner, address(this), tokenId, msg.sender);
    }
    _burn(address(this), tokenIds_.length * _unit());
  }

  /**
   *
   * Owner Functions *
   *
   */

  /**
   * @dev Sets the creator fee that is charged on every buy and sell. The fee is scaled to 1e18 = 100%.
   * Has to be smaller than 10%
   */
  function setCreatorFee(uint256 creatorFeePercentage_) external onlyOwner {
    require(
      creatorFeePercentage_ <= 10 * 1e18, "CollectionImpl: creator fee percentage must be <= 10%"
    );
    // if frozen, the creator fee can only be lowered
    if (bondingCurveFreeze) {
      require(
        creatorFeePercentage_ <= creatorFeePercentage,
        "CollectionImpl: creator fee can only be lowered"
      );
    }
    creatorFeePercentage = creatorFeePercentage_;

    emit CreatorFeePercentageChanged(creatorFeePercentage_);
  }

  function freezeCreatorFee() external onlyOwner {
    bondingCurveFreeze = true;

    emit CreatorFeeFrozen();
  }

  function setBaseUri(string memory baseUri_) external onlyOwner {
    if (metadataFreeze) {
      revert("CollectionImpl: metadata freeze");
    }
    baseUri = baseUri_;

    emit BaseUriChanged(baseUri_);
  }

  function setTokenUriContract(address tokenUriContract_) external onlyOwner {
    if (metadataFreeze) {
      revert("CollectionImpl: metadata freeze");
    }
    tokenUriContract = tokenUriContract_;

    emit TokenUriContractChanged(tokenUriContract_);
  }

  function freezeMetadata() external onlyOwner {
    metadataFreeze = true;

    emit MetadataFrozen();
  }

  function disableWhitelist() external onlyOwner {
    isWhitelistEnabled = false;

    emit WhitelistDisabled();
  }

  function modifyWhitelist(address[] memory addresses_, bool isWhitelisted_) external onlyOwner {
    require(isWhitelistEnabled, "CollectionImpl: whitelist is not enabled");
    for (uint256 i = 0; i < addresses_.length;) {
      whitelist[addresses_[i]] = isWhitelisted_;
      unchecked {
        i++;
      }
    }

    emit WhitelistModified(addresses_, isWhitelisted_);
  }

  function setWhitelistMintLimit(uint256 whitelistMintLimit_) external onlyOwner {
    require(isWhitelistEnabled, "CollectionImpl: whitelist is not enabled");
    whitelistMintLimit = whitelistMintLimit_;

    emit WhitelistMintLimitChanged(whitelistMintLimit_);
  }

  /**
   *
   * Buy and Sell  *
   *
   */
  function buy(uint256 nftAmount, uint256 deadline) external payable nonReentrant {
    require(nftAmount > 0, "CollectionImpl: amount must be > 0");
    if (isWhitelistEnabled) {
      require(whitelist[msg.sender], "CollectionImpl: not whitelisted");
      if (whitelistMintLimit > 0) {
        require(
          whitelistMinted[msg.sender] + nftAmount <= whitelistMintLimit,
          "CollectionImpl: whitelist mint limit reached"
        );
        whitelistMinted[msg.sender] += nftAmount;
      }
    }

    require(block.timestamp <= deadline, "CollectionImpl: deadline passed");

    // get the price and fees
    uint256 price = getPrice(bondingCurveSupply, nftAmount);

    ProtocolFeeSpecs memory protocolFeeSpecs = _getProtocolFeeSpecs();
    uint256 protocolFee = (price * protocolFeeSpecs.protocolFeePercentage) / 1e18;
    uint256 creatorFee = (price * creatorFeePercentage) / 1e18;

    // check if the user sent enough eth incl fees
    require(msg.value >= price + protocolFee + creatorFee, "CollectionImpl: not enough eth sent");

    bondingCurveSupply += nftAmount;

    // mint the nfts to the user
    _mintMultipleTo(msg.sender, nftAmount);

    // send out the fees
    Address.sendValue(payable(protocolFeeSpecs.protocolFeeCollector), protocolFee);
    Address.sendValue(creatorVault, creatorFee);

    // send the dust back to the sender
    uint256 dust = msg.value - price - protocolFee - creatorFee;
    if (dust > 0) {
      Address.sendValue(payable(msg.sender), dust);
    }

    emit Buy(msg.sender, nftAmount, price, protocolFee, creatorFee);
  }

  function sell(
    uint256[] memory tokenIds_,
    uint256 minPrice_, // min total eth the user wants to receive
    uint256 deadline_
  ) external nonReentrant {
    uint256 amount = tokenIds_.length;
    require(amount > 0, "CollectionImpl: no tokenIds");
    require(amount <= 100, "CollectionImpl: max 100 tokens");

    require(block.timestamp <= deadline_, "CollectionImpl: deadline passed");

    // get the price and fees
    uint256 price = getPrice(bondingCurveSupply - amount, amount);

    ProtocolFeeSpecs memory protocolFeeSpecs = _getProtocolFeeSpecs();
    uint256 protocolFee = (price * protocolFeeSpecs.protocolFeePercentage) / 1e18;
    uint256 creatorFee = (price * creatorFeePercentage) / 1e18;

    require(price - protocolFee - creatorFee >= minPrice_, "CollectionImpl: price too low");

    bondingCurveSupply -= amount;

    // burn the NFTs from the owner
    _bondingCurveBurnMultiple(tokenIds_);

    // send out the fees
    Address.sendValue(payable(protocolFeeSpecs.protocolFeeCollector), protocolFee);
    Address.sendValue(creatorVault, creatorFee);

    // send the price minus the fees back
    Address.sendValue(payable(msg.sender), price - protocolFee - creatorFee);

    emit Sell(msg.sender, amount, price, protocolFee, creatorFee);
  }

  function deflationarySell(uint256[] memory tokenIds_) external nonReentrant {
    require(isDeflationary, "CollectionImpl: not deflationary");
    uint256 amount = tokenIds_.length;
    require(amount > 0, "CollectionImpl: no tokenIds");
    require(amount <= 100, "CollectionImpl: max 100 tokens");

    // get the price and fees
    uint256 price = getPrice(deflationBurnCount, amount);

    ProtocolFeeSpecs memory protocolFeeSpecs = _getProtocolFeeSpecs();
    uint256 protocolFee = (price * protocolFeeSpecs.protocolFeePercentage) / 1e18;
    uint256 creatorFee = (price * creatorFeePercentage) / 1e18;

    // burn the NFTs from the owner
    _bondingCurveBurnMultiple(tokenIds_);

    deflationBurnCount += tokenIds_.length;

    // send out the fees
    Address.sendValue(payable(protocolFeeSpecs.protocolFeeCollector), protocolFee);
    Address.sendValue(creatorVault, creatorFee);

    // send the price minus the fees back
    Address.sendValue(payable(msg.sender), price - protocolFee - creatorFee);

    emit DeflationarySell(msg.sender, amount, price, protocolFee, creatorFee);
  }

  /**
   *
   * Price Related calculations *
   *
   */

  // returns the price for a given supply and purchase-amount
  function getPrice(uint256 supply, uint256 amount) public view returns (uint256) {
    // integral(supply):  supply * ((factor * supply ** exponent) / (exponent + 1) + c)
    // price: integral(supply + amount) - integral(supply)
    // This formula is derived from the above calculation.
    uint256 ePlusOne = bondingCurveSpecs.exponent + 1;
    // prettier-ignore
    return ((supply + amount) ** ePlusOne - supply ** ePlusOne) * bondingCurveSpecs.factor
      / ePlusOne + bondingCurveSpecs.c * amount;
  }

  function getBuyPriceExclusiveFees(uint256 amount_) public view returns (uint256) {
    uint256 supply = bondingCurveSupply;
    uint256 price = getPrice(supply, amount_);
    return price;
  }

  function getSellPriceExclusiveFees(uint256 amount_) public view returns (uint256) {
    uint256 supply = bondingCurveSupply;
    uint256 price = getPrice(supply - amount_, amount_);
    uint256 protocolFee = (price * getProtocolFeePercentage()) / 1e18;
    uint256 creatorFee = (price * creatorFeePercentage) / 1e18;
    return price - protocolFee - creatorFee;
  }

  function getBuyPriceInclFees(uint256 amount_) public view returns (uint256) {
    uint256 supply = bondingCurveSupply;
    uint256 price = getPrice(supply, amount_);
    uint256 protocolFee = (price * getProtocolFeePercentage()) / 1e18;
    uint256 creatorFee = (price * creatorFeePercentage) / 1e18;
    return price + protocolFee + creatorFee;
  }

  function getSellPriceInclFees(uint256 amount_) public view returns (uint256) {
    uint256 supply = bondingCurveSupply;
    uint256 price = getPrice(supply - amount_, amount_);
    return price;
  }

  function getProtocolFeePercentage() public view returns (uint256) {
    return _getProtocolFeeSpecs().protocolFeePercentage;
  }

  /**
   *
   * Internal
   *
   */
  function _getProtocolFeeSpecs() internal view returns (ProtocolFeeSpecs memory) {
    return IRouter(router).protocolFeeSpecs();
  }

  /**
   *
   * Receive Function *
   *
   */
  receive() external payable override {
    emit PaymentReceived(msg.sender, msg.value);
  }

  /**
   *
   * Other *
   *
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function _tokenURI(uint256 id) internal view virtual override returns (string memory) {
    if (tokenUriContract != address(0)) {
      return ITokenUri(tokenUriContract).tokenURI(id, address(this));
    } else if (bytes(baseUri).length > 0) {
      return string.concat(baseUri, id.toString());
    } else {
      return ITokenUri(tokenUriFallbackContract).tokenURI(id, address(this));
    }
  }

  /// @dev Amount of token balance that is equal to one NFT.
  function _unit() internal view virtual override returns (uint256) {
    return units;
  }

  function _utfStringLength(string memory str) internal pure returns (uint256 length) {
    uint256 i = 0;
    bytes memory string_rep = bytes(str);

    while (i < string_rep.length) {
      if (string_rep[i] >> 7 == 0) {
        i += 1;
      } else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) {
        i += 2;
      } else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) {
        i += 3;
      } else if (string_rep[i] >> 3 == bytes1(uint8(0x1E))) {
        i += 4;
      } else {
        i += 1;
      }

      length++;
    }
  }
}
