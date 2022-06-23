// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC4973Permit} from "./interfaces/IERC4973Permit.sol";

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

  function testIERC4973Permit() public {
    bytes4 interfaceId = type(IERC4973Permit).interfaceId;
    assertEq(interfaceId, bytes4(0x6b65efaa));
    assertTrue(abt.supportsInterface(interfaceId));
  }

  function testMintWithDifferentTokenURI() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    string memory falseTokenURI = "https://badstuff.com";
    bytes32 hash = abt.getMintPermitMessageHash(fromAddress, to, falseTokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);
    address unauthorizedFrom = address(1337);

    vm.expectRevert(bytes("mintWithPermission: invalid permission"));
    uint256 tokenId = abt.mintWithPermission(
      unauthorizedFrom,
      tokenURI,
      v,
      r,
      s
    );
    assertEq(0, tokenId);
  }

  function testMintWithUnauthorizedSender() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getMintPermitMessageHash(fromAddress, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);
    address unauthorizedFrom = address(1337);

    vm.expectRevert(bytes("mintWithPermission: invalid permission"));
    uint256 tokenId = abt.mintWithPermission(
      unauthorizedFrom,
      tokenURI,
      v,
      r,
      s
    );
    assertEq(0, tokenId);
  }

  function testMintWithPermit() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getMintPermitMessageHash(fromAddress, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);

    uint256 tokenId = abt.mintWithPermission(
      fromAddress,
      tokenURI,
      v,
      r,
      s
    );
    assertEq(tokenId, 0);
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
  }

  function testMintWithAlreadyUsedVoucher() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getMintPermitMessageHash(fromAddress, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(fromPrivateKey, hash);

    // first attempt to mint should pass
    abt.mintWithPermission(
      fromAddress,
      tokenURI,
      v,
      r,
      s
    );

    // second attempt to mint should revert
    vm.expectRevert(bytes("mintWithPermission: voucher already used"));
    abt.mintWithPermission(
      fromAddress,
      tokenURI,
      v,
      r,
      s
    );
  }
}

