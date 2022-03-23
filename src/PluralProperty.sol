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
    require(_exists(tokenId), "URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    require(_exists(tokenId), "URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "owner query for nonexistent token");
    return owner;
  }


  function mint(
    Perwei memory taxRate,
    string calldata uri
  ) external payable returns (uint256) {
    require(msg.value > 0, "must send eth");

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
    require(assessment.seller != address(0), "offer doesn't exist");

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
