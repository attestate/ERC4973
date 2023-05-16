// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from
  "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721Metadata} from
  "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import {IERC4973} from "./interfaces/IERC4973.sol";
import {ERC4973} from "./ERC4973.sol";

contract ERC1271Mock is ERC721Holder {
  bytes4 internal constant MAGICVALUE = 0x1626ba7e;
  bool private pass;

  constructor(bool pass_) {
    pass = pass_;
  }

  function isValidSignature(bytes32 hash, bytes memory signature)
    public
    view
    returns (bytes4)
  {
    if (pass) {
      return MAGICVALUE;
    } else {
      revert("permit not granted");
    }
  }
}

contract AccountAbstraction is ERC1271Mock {
  constructor(bool pass) ERC1271Mock(pass) {}

  function give(
    address collection,
    address to,
    bytes calldata metadata,
    bytes calldata signature
  ) external virtual returns (uint256) {
    return ERC4973(collection).give(to, metadata, signature);
  }

  function take(
    address collection,
    address from,
    bytes calldata metadata,
    bytes calldata signature
  ) external virtual returns (uint256) {
    return ERC4973(collection).take(from, metadata, signature);
  }

  function unequip(address collection, uint256 tokenId) public virtual {
    return ERC4973(collection).unequip(tokenId);
  }
}

contract NonAuthorizedCaller is ERC721Holder {
  function unequip(address collection, uint256 tokenId) external {
    AccountBoundToken abt = AccountBoundToken(collection);
    abt.unequip(tokenId);
  }
}

contract AccountBoundToken is ERC4973 {
  constructor() ERC4973("Name", "Symbol", "Version") {}

  function getHash(address from, address to, bytes calldata metadata)
    public
    view
    returns (bytes32)
  {
    return _getHash(from, to, metadata);
  }

  function mint(address to, uint256 tokenId) external {
    _mint(to, tokenId);
  }
}

contract ERC4973Test is Test, ERC721Holder {
  ERC1271Mock approver;
  ERC1271Mock rejecter;
  AccountBoundToken abt;
  AccountAbstraction aa;

  address passiveAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 passivePrivateKey =
    0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

  string constant tokenURI = "https://example.com/metadata.json";

  event Transfer(
    address indexed from, address indexed to, uint256 indexed tokenId
  );

  function setUp() public {
    abt = new AccountBoundToken();
    approver = new ERC1271Mock(true);
    rejecter = new ERC1271Mock(false);
    aa = new AccountAbstraction(true);
  }

  function testIERC721() public {
    assertTrue(abt.supportsInterface(type(IERC721).interfaceId));
  }

  function testIERC165() public {
    assertTrue(abt.supportsInterface(type(IERC165).interfaceId));
  }

  function testIERC721Metadata() public {
    assertTrue(abt.supportsInterface(type(IERC721Metadata).interfaceId));
  }

  function testIERC4973() public {
    bytes4 interfaceId = type(IERC4973).interfaceId;
    assertEq(interfaceId, bytes4(0xf8801853));
    assertTrue(abt.supportsInterface(interfaceId));
  }

  function testUnequippingAsNonAuthorizedAccount() public {
    address from = address(0);
    address to = address(this);
    uint256 tokenId = 0;

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, to, tokenId);
    abt.mint(to, tokenId);

    assertEq(abt.ownerOf(tokenId), to);

    NonAuthorizedCaller nac = new NonAuthorizedCaller();
    vm.expectRevert(bytes("unequip: sender must be owner"));

    nac.unequip(address(abt), tokenId);
  }

  function testUnequippingNonExistentTokenId() public {
    address to = address(this);
    address from = address(0);
    uint256 tokenId = 0;

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, to, tokenId);
    abt.mint(to, tokenId);

    assertEq(abt.ownerOf(tokenId), to);

    NonAuthorizedCaller nac = new NonAuthorizedCaller();
    vm.expectRevert(bytes("ERC721: invalid token ID"));

    nac.unequip(address(abt), 1337);
  }

  function testGiveWithRejectingERC1271Contract() public {
    address to = address(rejecter);
    bytes memory signature;

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    abt.give(to, bytes(tokenURI), signature);
  }

  function testTakeWithRejectingERC1271Contract() public {
    address from = address(rejecter);
    bytes memory signature;

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    abt.take(from, bytes(tokenURI), signature);
  }

  function testGiveWithApprovingERC1271Contract() public {
    address to = address(approver);
    bytes memory signature;

    uint256 tokenId = abt.give(to, bytes(tokenURI), signature);
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
  }

  function testTakeWithApprovingERC1271Contract() public {
    address to = address(this);
    address from = address(approver);
    bytes memory signature;

    uint256 tokenId = abt.take(from, bytes(tokenURI), signature);
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
  }

  function testTakeWithDifferentTokenURI() public {
    address to = address(this);

    string memory falseTokenURI = "https://badstuff.com";
    bytes32 hash = abt.getHash(passiveAddress, to, bytes(falseTokenURI));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = abt.take(passiveAddress, bytes(tokenURI), signature);
    assertEq(0, tokenId);
  }

  function testGiveWithDifferentTokenURI() public {
    address from = address(this);
    address to = passiveAddress;

    string memory falseTokenURI = "https://badstuff.com";
    bytes32 hash = abt.getHash(from, to, bytes(falseTokenURI));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = abt.give(to, bytes(tokenURI), signature);
    assertEq(0, tokenId);
  }

  function testGiveWithUnauthorizedSender() public {
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = abt.getHash(from, to, bytes(tokenURI));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    address unauthorizedTo = address(1337);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = abt.give(unauthorizedTo, bytes(tokenURI), signature);
    assertEq(0, tokenId);
  }

  function testTakeWithUnauthorizedSender() public {
    address to = address(this);

    bytes32 hash = abt.getHash(passiveAddress, to, bytes(tokenURI));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    address unauthorizedFrom = address(1337);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = abt.take(unauthorizedFrom, bytes(tokenURI), signature);
    assertEq(0, tokenId);
  }

  function testGiveEOA() public {
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = abt.getHash(from, to, bytes(tokenURI));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    bytes memory expected =
      hex"0e1183b212232b4f1c3e11edd00059fb01710c0335b81c11a43d11d5b7cd01d55483b1a1432f76c4d3cab1bb2607622fd173f8f3d6bdbe8927c4706f9be447321b";
    assertEq(signature, expected);

    uint256 tokenId = abt.give(to, bytes(tokenURI), signature);
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
  }

  function testGiveAndUnequipAndRegive() public {
    address to = address(aa);
    bytes memory signature;

    uint256 tokenId = abt.give(to, bytes(tokenURI), signature);
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
    aa.unequip(address(abt), tokenId);
    assertEq(abt.balanceOf(to), 0);
    uint256 tokenId2 = abt.give(to, bytes(tokenURI), signature);
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId2), tokenURI);
    assertEq(abt.ownerOf(tokenId2), to);
  }

  function testTakeAndUnequipAndRetake() public {
    address to = address(this);

    bytes32 hash = abt.getHash(to, passiveAddress, bytes(tokenURI));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    uint256 tokenId = abt.take(passiveAddress, bytes(tokenURI), signature);
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
    abt.unequip(tokenId);
    assertEq(abt.balanceOf(to), 0);
    uint256 tokenId2 = abt.take(passiveAddress, bytes(tokenURI), signature);
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId2), tokenURI);
    assertEq(abt.ownerOf(tokenId2), to);
  }

  function testTakeEOA() public {
    address to = address(this);

    bytes32 hash = abt.getHash(to, passiveAddress, bytes(tokenURI));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    bytes memory expected =
      hex"0e1183b212232b4f1c3e11edd00059fb01710c0335b81c11a43d11d5b7cd01d55483b1a1432f76c4d3cab1bb2607622fd173f8f3d6bdbe8927c4706f9be447321b";
    assertEq(signature, expected);

    uint256 tokenId = abt.take(passiveAddress, bytes(tokenURI), signature);
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
  }

  function testGiveWithAlreadyUsedVoucher() public {
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = abt.getHash(from, to, bytes(tokenURI));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    abt.give(to, bytes(tokenURI), signature);

    vm.expectRevert(bytes("_safeCheckAgreement: already used"));
    abt.give(to, bytes(tokenURI), signature);
  }

  function testTakeWithAlreadyUsedVoucher() public {
    address to = address(this);

    bytes32 hash = abt.getHash(to, passiveAddress, bytes(tokenURI));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    abt.take(passiveAddress, bytes(tokenURI), signature);

    vm.expectRevert(bytes("_safeCheckAgreement: already used"));
    abt.take(passiveAddress, bytes(tokenURI), signature);
  }

  function testPreventGivingToSelf() public {
    address to = address(aa);
    bytes memory signature;

    vm.expectRevert(bytes("give: cannot give from self"));
    aa.give(address(abt), to, bytes(tokenURI), signature);
  }

  function testPreventTakingToSelf() public {
    address from = address(aa);
    bytes memory signature;

    vm.expectRevert(bytes("take: cannot take from self"));
    aa.take(address(abt), from, bytes(tokenURI), signature);
  }

  function testTryTransferFromABT() public {
    address to = address(approver);
    bytes memory signature;

    uint256 tokenId = abt.give(to, bytes(tokenURI), signature);

    vm.prank(to);
    vm.expectRevert(bytes("Not implemented"));
    abt.transferFrom(to, address(abt), tokenId);
  }

  function testTrySafeTransferFromABT() public {
    address to = address(approver);
    bytes memory signature;

    uint256 tokenId = abt.give(to, bytes(tokenURI), signature);

    vm.prank(to);
    vm.expectRevert(bytes("Not implemented"));
    abt.safeTransferFrom(to, address(abt), tokenId);
  }

  function testTrySafeTransferFromWithDataABT() public {
    address to = address(approver);
    bytes memory signature;

    uint256 tokenId = abt.give(to, bytes(tokenURI), signature);

    vm.prank(to);
    vm.expectRevert(bytes("Not implemented"));
    abt.safeTransferFrom(to, address(abt), tokenId, "");
  }
}
