// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import {ERC165} from "openzeppelin-contracts/utils/introspection/ERC165.sol";
import {IERC165} from "openzeppelin-contracts/utils/introspection/IERC165.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {Counters} from "openzeppelin-contracts/utils/Counters.sol";

import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IPluralProperty} from "./interfaces/IPluralProperty.sol";
import {Perwei, Period, Harberger} from "./Harberger.sol";

struct Assessment {
  address seller;
  uint256 startBlock;
  uint256 startPrice;
  Perwei taxRate;
}

abstract contract PluralProperty is ERC165, IERC721Metadata, IPluralProperty {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  string private _name;
  string private _symbol;

  mapping(uint256 => address) private _owners;
  mapping(uint256 => Assessment) private _assessments;
  mapping(uint256 => string) private _tokenURIs;

  constructor(
    string memory name_,
    string memory symbol_
  ) {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
    return
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "tokenURI: token doesn't exist");
    return _tokenURIs[tokenId];
  }

  function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
    require(_exists(_tokenId), "_setTokenURI: token doesn't exist");
    _tokenURIs[_tokenId] = _tokenURI;
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ownerOf: token doesn't exist");
    return owner;
  }

  function mint(
    Perwei memory taxRate,
    string calldata uri
  ) external payable returns (uint256) {
    require(msg.value > 0, "mint: not enough ETH");

    uint256 tokenId = _tokenIds.current();
    _owners[tokenId] = msg.sender;
    _setTokenURI(tokenId, uri);
    _tokenIds.increment();

    Assessment memory assessment = Assessment(
      msg.sender,
      block.number,
      msg.value,
      taxRate
    );
    _assessments[tokenId] = assessment;

    emit Transfer(address(0), msg.sender, tokenId);
    return tokenId;
  }

  function buy(
    uint256 tokenId
  ) external payable {
    Assessment memory assessment = _assessments[tokenId];
    require(_exists(tokenId), "buy: token doesn't exist");

    uint256 nextPrice = Harberger.pay(
      assessment.taxRate,
      Period(assessment.startBlock, block.number),
      assessment.startPrice
    );

    payable(assessment.seller).transfer(nextPrice);
    Assessment memory nextAssessment = Assessment(
      msg.sender,
      block.number,
      msg.value,
      assessment.taxRate
    );
    _assessments[tokenId] = nextAssessment;
    _owners[tokenId] = msg.sender;
    emit Transfer(assessment.seller, msg.sender, tokenId);
  }
}
