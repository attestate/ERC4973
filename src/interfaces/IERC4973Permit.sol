// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

/// @title Account-bound tokens, optional permissioned minting extension
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
interface IERC4973Permit {
  function mintWithPermission(address from, uint256 tokenId, string calldata uri, uint8 v, bytes32 r, bytes32 s) external returns (uint256);
}