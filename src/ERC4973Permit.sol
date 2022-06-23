// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import {ERC4973} from "./ERC4973.sol";
import {IERC4973Permit} from "./interfaces/IERC4973Permit.sol";

/// @notice Reference implementation of ERC4973Permit
/// @author Rahul Rumalla, Tim Daubenschuetz (https://github.com/rugpullindex/ERC4973/blob/master/src/ERC4973Permit.sol)
abstract contract ERC4973Permit is ERC4973, EIP712, IERC4973Permit {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  bytes32 private immutable MINT_PERMIT_TYPEHASH =
    keccak256(
      "MintPermit(address from,address to,string tokenURI)"
  );

  using BitMaps for BitMaps.BitMap;
  BitMaps.BitMap private _bitMap;

  constructor(
    string memory name,
    string memory symbol,
    string memory version
  ) ERC4973(name, symbol) EIP712(name, version) {}


  function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return
      interfaceId == type(IERC4973Permit).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function mintWithPermission(
    address from,
    string calldata uri,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256) {
    bytes32 mintPermitHash = getMintPermitMessageHash(
      from,
      msg.sender,
      uri
    );

    uint256 index = uint256(mintPermitHash);

    require(
      !_bitMap.get(index),
      "mintWithPermission: voucher already used"
    );

    require(
      _isPermittedToMint(from, mintPermitHash, v, r, s),
      "mintWithPermission: invalid permission"
    );
    uint256 tokenId = _tokenIds.current();
    _mint(msg.sender, tokenId, uri);
    _tokenIds.increment();
    _bitMap.set(index);
    return tokenId;
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
    bytes32 mintPermitHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (bool) {
    address signer = ECDSA.recover(mintPermitHash, v, r, s);
    return signer == from;
  }
}
