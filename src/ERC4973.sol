// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import {SignatureChecker} from
  "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {EIP712} from
  "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {
  ERC721,
  ERC721URIStorage
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import {IERC4973} from "./interfaces/IERC4973.sol";

bytes32 constant AGREEMENT_HASH =
  keccak256("Agreement(address active,address passive,bytes metadata)");

/// @notice Reference implementation of EIP-4973 tokens.
/// @author Tim Daubenschütz, Rahul Rumalla (https://github.com/rugpullindex/ERC4973/blob/master/src/ERC4973.sol)
abstract contract ERC4973 is EIP712, ERC721URIStorage, IERC4973 {
  using BitMaps for BitMaps.BitMap;

  BitMaps.BitMap private _usedHashes;

  constructor(string memory name, string memory symbol, string memory version)
    EIP712(name, version)
    ERC721(name, symbol)
  {}

  function decodeURI(bytes calldata metadata)
    public
    virtual
    returns (string memory)
  {
    return string(metadata);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return interfaceId == type(IERC4973).interfaceId
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
    _usedHashes.set(tokenId);
    return tokenId;
  }

  function _safeCheckAgreement(
    address active,
    address passive,
    bytes calldata metadata,
    bytes calldata signature
  ) internal virtual returns (uint256) {
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
    bytes32 structHash = keccak256(
      abi.encode(AGREEMENT_HASH, active, passive, keccak256(metadata))
    );
    return _hashTypedDataV4(structHash);
  }

  // Block the ERC721 transfers

  function transferFrom(address, address, uint256) public virtual override {
    revert("Not implemented");
  }

  function safeTransferFrom(address, address, uint256) public virtual override {
    revert("Not implemented");
  }

  function safeTransferFrom(address, address, uint256, bytes memory)
    public
    virtual
    override
  {
    revert("Not implemented");
  }
}
