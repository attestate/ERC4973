// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import {IERC165} from "./interfaces/IERC165.sol";

import {ERC4973Permit} from "./ERC4973Permit.sol";

contract AccountBoundToken is ERC4973Permit {
  constructor() ERC4973Permit("Name", "Symbol", "Version") {}
}

contract ERC4973Test is Test {
  AccountBoundToken abt;

  address fromAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 fromPrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

  function setUp() public {
    abt = new AccountBoundToken();
  }

  function testMintWithDifferentTokenURI() public {
    uint256 tokenId = 0;
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    string memory falseTokenURI = "https://badstuff.com";
    bytes32 hash = abt.getMintPermitMessageHash(fromAddress, to, falseTokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);
    address unauthorizedFrom = address(1337);

    vm.expectRevert(bytes("mintWithPermission: invalid permission"));
    abt.mintWithPermission(
      unauthorizedFrom,
      tokenId,
      tokenURI,
      v,
      r,
      s
    );
  }

  function testMintWithUnauthorizedSender() public {
    uint256 tokenId = 0;
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getMintPermitMessageHash(fromAddress, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);
    address unauthorizedFrom = address(1337);

    vm.expectRevert(bytes("mintWithPermission: invalid permission"));
    abt.mintWithPermission(
      unauthorizedFrom,
      tokenId,
      tokenURI,
      v,
      r,
      s
    );
  }

  function testMintWithPermit() public {
    uint256 tokenId = 0;
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getMintPermitMessageHash(fromAddress, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);

    abt.mintWithPermission(
      fromAddress,
      tokenId,
      tokenURI,
      v,
      r,
      s
    );
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
  }
}

