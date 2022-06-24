// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC4973Permit} from "./interfaces/IERC4973Permit.sol";

import {ERC4973Permit} from "./ERC4973Permit.sol";

contract AccountBoundToken is ERC4973Permit {
  constructor() ERC4973Permit("Name", "Symbol", "Version") {}

  function getHash(
    address from,
    address to,
    string calldata tokenURI
  ) public view returns (bytes32) {
    return _getHash(from, to, tokenURI);
  }
}

contract ERC4973Test is Test {
  AccountBoundToken abt;

  address fromAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 fromPrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

  function setUp() public {
    abt = new AccountBoundToken();
  }

  function testIERC4973Permit() public {
    bytes4 interfaceId = type(IERC4973Permit).interfaceId;
    assertEq(interfaceId, bytes4(0x8fac1c1c));
    assertTrue(abt.supportsInterface(interfaceId));
  }

  function testMintWithDifferentTokenURI() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    string memory falseTokenURI = "https://badstuff.com";
    bytes32 hash = abt.getHash(fromAddress, to, falseTokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    address unauthorizedFrom = address(1337);

    vm.expectRevert(bytes("mintWithPermission: invalid signature"));
    uint256 tokenId = abt.mintWithPermission(
      unauthorizedFrom,
      tokenURI,
      signature
    );
    assertEq(0, tokenId);
  }

  function testMintWithUnauthorizedSender() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getHash(fromAddress, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    address unauthorizedFrom = address(1337);

    vm.expectRevert(bytes("mintWithPermission: invalid signature"));
    uint256 tokenId = abt.mintWithPermission(
      unauthorizedFrom,
      tokenURI,
      signature
    );
    assertEq(0, tokenId);
  }

  function testMintWithPermit() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getHash(fromAddress, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    uint256 tokenId = abt.mintWithPermission(
      fromAddress,
      tokenURI,
      signature
    );
    assertEq(tokenId, 0);
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
  }

  function testMintWithAlreadyUsedVoucher() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getHash(fromAddress, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    abt.mintWithPermission(
      fromAddress,
      tokenURI,
      signature
    );

    vm.expectRevert(bytes("mintWithPermission: already used"));
    abt.mintWithPermission(
      fromAddress,
      tokenURI,
      signature
    );
  }
}

