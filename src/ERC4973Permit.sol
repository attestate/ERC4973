// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {ERC4973} from "./ERC4973.sol";
import {IERC4973Permit} from "./interfaces/IERC4973Permit.sol"; 

/// @notice Reference implementation of ERC4973Permit
/// @author Rahul Rumalla, Tim Daub (https://github.com/rugpullindex/ERC4973/blob/master/src/ERC4973Permit.sol)
abstract contract ERC4973Permit is ERC4973, EIP712, IERC4973Permit {
  bytes32 private immutable MINT_PERMIT_TYPEHASH =
    keccak256(
      "MintPermit(address from,address to,string tokenURI)"
  );

  constructor(
    string memory name,
    string memory symbol,
    string memory version
  ) ERC4973(name, symbol) EIP712(name, version) {}

  function mintWithPermission(
    address from,
    uint256 tokenId,
    string calldata uri,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256) {
    require(
      _isPermittedToMint(from, msg.sender, uri, v, r, s),
      "mintWithPermission: invalid permission"
    );

    return _mint(msg.sender, tokenId, uri);
  }

  function getMintPermitMessageHash(
    address from,
    address to,
    string calldata tokenURI
  ) public view returns (bytes32) {
    bytes32 structHash = keccak256(
      abi.encode(MINT_PERMIT_TYPEHASH, from, to, tokenURI)
    );
    return _hashTypedDataV4(structHash);
  }

  function _isPermittedToMint(
    address from,
    address to,
    string calldata tokenURI,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal view returns (bool) {
    bytes32 mintPermitHash = getMintPermitMessageHash(
      from,
      to,
      tokenURI
    );
    address signer = ECDSA.recover(mintPermitHash, v, r, s);
    return signer == from;
  }
}
