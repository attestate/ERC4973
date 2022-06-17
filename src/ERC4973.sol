// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import {ERC165} from "./ERC165.sol";
import {ERC4973Permit} from "./ERC4973Permit.sol";

import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC4973} from "./interfaces/IERC4973.sol";

abstract contract ERC4973 is ERC165, ERC4973Permit, IERC721Metadata, IERC4973 {
  string private _name;
  string private _symbol;

  mapping(uint256 => address) private _owners;
  mapping(uint256 => string) private _tokenURIs;

  constructor(
    string memory name_,
    string memory symbol_
  ) ERC4973Permit(name_) {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId) public view override returns (bool)
  {
    return
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC4973).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
  {
    require(_exists(tokenId), "tokenURI: token doesn't exist");
    return _tokenURIs[tokenId];
  }

  function burn(uint256 _tokenId) public virtual override {
    require(msg.sender == ownerOf(_tokenId), "burn: sender must be owner");
    _burn(_tokenId);
  }

  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ownerOf: token doesn't exist");
    return owner;
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _mint(
    address to,
    uint256 tokenId,
    string memory uri
  ) internal virtual returns (uint256) {
    require(!_exists(tokenId), "mint: tokenID exists");
    _owners[tokenId] = to;
    _tokenURIs[tokenId] = uri;
    emit Attest(to, tokenId);
    return tokenId;
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);

    delete _owners[tokenId];
    delete _tokenURIs[tokenId];

    emit Revoke(owner, tokenId);
  }

  function _mintWithPermission(
    address from,
    address to,
    uint256 tokenId,
    string memory uri,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal virtual returns (uint256) {
    require(!_isPermittedToMint(from, to, uri, v, r, s), "_mintWithPermission: unauthorized caller");

    return _mint(to, tokenId, uri);
  }
}
