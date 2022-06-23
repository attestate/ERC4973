// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

/// @title Account-bound tokens, optional permissioned minting extension
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
/// Note: the ERC-165 identifier for this interface is 0x6b65efaa
interface IERC4973Permit {
  function mintWithPermission(address from, string calldata uri, uint8 v, bytes32 r, bytes32 s) external returns (uint256);
}