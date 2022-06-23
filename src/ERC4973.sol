// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import {ERC165} from "./ERC165.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC4973} from "./interfaces/IERC4973.sol";


/// @notice Reference implementation of EIP-4973 tokens.
/// @author TimDaub (https://github.com/rugpullindex/ERC4973/blob/master/src/ERC4973.sol)
abstract contract ERC4973 is ERC165, IERC721Metadata, IERC4973 {
  string private _name;
  string private _symbol;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  mapping(uint256 => address) private _owners;
  mapping(uint256 => string) private _tokenURIs;
  mapping(address => uint256) private _balances;

  constructor(
    string memory name_,
    string memory symbol_
  ) {
    _name = name_;
    _symbol = symbol_;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
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

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "tokenURI: token doesn't exist");
    return _tokenURIs[tokenId];
  }

  function burn(uint256 tokenId) public virtual override {
    require(msg.sender == ownerOf(tokenId), "burn: sender must be owner");
    _burn(tokenId);
  }

  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), "balanceOf: address zero is not a valid owner");
    return _balances[owner];
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
    string memory uri
  ) internal virtual returns (uint256) {
    uint256 tokenId = _tokenIds.current();

    _balances[to] += 1;
    _owners[tokenId] = to;
    _tokenURIs[tokenId] = uri;
    
    emit Attest(to, tokenId);
    
    _tokenIds.increment();
    
    return tokenId;
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);

    _balances[owner] -= 1;
    delete _owners[tokenId];
    delete _tokenURIs[tokenId];

    emit Revoke(owner, tokenId);
  }
}
