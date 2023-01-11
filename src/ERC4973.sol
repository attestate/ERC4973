// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {SignatureChecker} from
  "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {EIP712} from
  "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from
  "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import {IERC4973} from "./interfaces/IERC4973.sol";
import {IERC5192} from "./interfaces/IERC5192.sol";

bytes32 constant AGREEMENT_HASH =
  keccak256("Agreement(address active,address passive,bytes metadata)");

/// @notice Reference implementation of EIP-4973 tokens.
/// @author Tim Daubenschütz, Rahul Rumalla (https://github.com/rugpullindex/ERC4973/blob/master/src/ERC4973.sol)
abstract contract ERC4973 is
  EIP712,
  ERC721,
  ERC721URIStorage,
  IERC4973,
  IERC5192
{
  using BitMaps for BitMaps.BitMap;

  BitMaps.BitMap private _usedHashes;

  modifier notSupported() {
    revert("notSupported: Soulbound NFT EIP-5192");
    _;
  }

  function getApproved(uint256) public pure override returns (address) {
    return address(0x0);
  }

  function isApprovedForAll(address, address)
    public
    pure
    override
    returns (bool)
  {
    return false;
  }

  function approve(address, uint256) public override notSupported {}

  function setApprovalForAll(address, bool) public override notSupported {}

  function transferFrom(address, address, uint256) public override notSupported {}

  function safeTransferFrom(address, address, uint256)
    public
    override
    notSupported
  {}

  function safeTransferFrom(address, address, uint256, bytes memory)
    public
    override
    notSupported
  {}

  constructor(string memory name, string memory symbol, string memory version)
    EIP712(name, version)
    ERC721(name, symbol)
  {}

  function _burn(uint256 tokenId) internal override (ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override (ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function locked(uint256 tokenId) external view returns (bool) {
    require(_exists(tokenId), "locked: tokenId doesn't exist");
    return true;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return interfaceId == type(IERC4973).interfaceId
      || interfaceId == type(IERC5192).interfaceId
      || super.supportsInterface(interfaceId);
  }

  function unequip(uint256 tokenId) public virtual override {
    require(msg.sender == ownerOf(tokenId), "unequip: sender must be owner");
    _usedHashes.unset(tokenId);
    _burn(tokenId);
  }

  function give(address to, bytes calldata metadata, bytes calldata signature)
    external
    virtual
    returns (uint256)
  {
    require(msg.sender != to, "give: cannot give from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, to, metadata, signature);
    string memory uri = decodeURI(metadata);
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, uri);
    _transfer(msg.sender, to, tokenId);
    emit Locked(tokenId);
    _usedHashes.set(tokenId);
    return tokenId;
  }

  function take(address from, bytes calldata metadata, bytes calldata signature)
    external
    virtual
    returns (uint256)
  {
    require(msg.sender != from, "take: cannot take from self");
    uint256 tokenId = _safeCheckAgreement(msg.sender, from, metadata, signature);
    string memory uri = decodeURI(metadata);
    _safeMint(from, tokenId);
    _setTokenURI(tokenId, uri);
    _transfer(from, msg.sender, tokenId);
    emit Locked(tokenId);
    _usedHashes.set(tokenId);
    return tokenId;
  }

  function decodeURI(bytes calldata metadata)
    public
    virtual
    returns (string memory)
  {
    return string(metadata);
  }

  function _safeCheckAgreement(
    address active,
    address passive,
    bytes calldata metadata,
    bytes calldata signature
  )
    internal
    virtual
    returns (uint256)
  {
    bytes32 hash = _getHash(active, passive, metadata);
    uint256 tokenId = uint256(hash);

    require(
      SignatureChecker.isValidSignatureNow(passive, hash, signature),
      "_safeCheckAgreement: invalid signature"
    );
    require(!_usedHashes.get(tokenId), "_safeCheckAgreement: already used");
    return tokenId;
  }

  function _getHash(address active, address passive, bytes calldata metadata)
    internal
    view
    returns (bytes32)
  {
    bytes32 structHash =
      keccak256(abi.encode(AGREEMENT_HASH, active, passive, keccak256(metadata)));
    return _hashTypedDataV4(structHash);
  }
}
