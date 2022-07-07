// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

/// @title Account-bound tokens
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
/// Note: the ERC-165 identifier for this interface is 0x5164cf47
interface IERC4973 {
  /// @dev This emits when ownership of any ABT changes by any mechanism.
  ///  This event emits when ABTs are given or equipped (`from` == 0) and
  ///  unequipped (`to` == 0).
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  /// @notice Count all ABTs assigned to an owner
  /// @dev ABTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param owner An address for whom to query the balance
  /// @return The number of ABTs owned by `owner`, possibly zero
  function balanceOf(address owner) external view returns (uint256);
  /// @notice Find the address bound to an ERC4973 account-bound token
  /// @dev ABTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param tokenId The identifier for an ABT
  /// @return The address of the owner bound to the ABT
  function ownerOf(uint256 tokenId) external view returns (address);
  /// @notice Removes the `tokenId` from an account. At any time, an ABT
  ///  receiver must be able to disassociate themselves from an ABT publicly
  /// through calling this function.
  /// @dev Must emit a `event Transfer` with the `address to` field pointing to
  ///  the zero address.
  /// @param tokenId The identifier for an ABT
  function unequip(uint256 tokenId) external;
  function give(
    address to,
    string calldata uri,
    bytes calldata signature
  ) external returns (uint256);
  function take(
    address from,
    string calldata uri,
    bytes calldata signature
  ) external returns (uint256);
}
