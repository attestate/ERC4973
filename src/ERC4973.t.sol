// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import {IERC165} from "./interfaces/IERC165.sol";

import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC4973} from "./interfaces/IERC4973.sol";
import {ERC4973} from "./ERC4973.sol";

contract ERC1271Mock {
  bytes4 constant internal MAGICVALUE = 0x1626ba7e;
  bool private pass;

  constructor(bool pass_) {
    pass = pass_;
  }

  function isValidSignature(
    bytes32 hash,
    bytes memory signature
  ) public view returns (bytes4) {
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
    string calldata uri,
    bytes calldata signature
  ) external virtual returns (uint256) {
    return ERC4973(collection).give(to, uri, signature);
  }

  function take(
    address collection,
    address from,
    string calldata uri,
    bytes calldata signature
  ) external virtual returns (uint256) {
    return ERC4973(collection).take(from, uri, signature);
  }

  function unequip(address collection, uint256 tokenId) public virtual {
    return ERC4973(collection).unequip(tokenId);
  }
}

contract AccountBoundToken is ERC4973 {
  constructor() ERC4973("Name", "Symbol", "Version") {}

  function getHash(
    address from,
    address to,
    string calldata tokenURI
  ) public view returns (bytes32) {
    return _getHash(from, to, tokenURI);
  }

  function mint(
    address to,
    uint256 tokenId,
    string calldata uri
  ) external returns (uint256) {
    return super._mint(to, tokenId, uri);
  }
}

contract NonAuthorizedCaller {
  function unequip(address collection, uint256 tokenId) external {
    AccountBoundToken abt = AccountBoundToken(collection);
    abt.unequip(tokenId);
  }
}

contract ERC4973Test is Test {
  ERC1271Mock approver;
  ERC1271Mock rejecter;
  AccountBoundToken abt;
  AccountAbstraction aa;

  address passiveAddress = 0x0f6A79A579658E401E0B81c6dde1F2cd51d97176;
  uint256 passivePrivateKey = 0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39;

  function setUp() public {
    abt = new AccountBoundToken();
    approver = new ERC1271Mock(true);
    rejecter = new ERC1271Mock(false);
    aa = new AccountAbstraction(true);
  }

  function testIERC165() public {
    assertTrue(abt.supportsInterface(type(IERC165).interfaceId));
  }

  function testIERC721Metadata() public {
    assertTrue(abt.supportsInterface(type(IERC721Metadata).interfaceId));
  }

  function testIERC4973() public {
    bytes4 interfaceId = type(IERC4973).interfaceId;
    assertEq(interfaceId, bytes4(0x8d7bac72));
    assertTrue(abt.supportsInterface(interfaceId));
  }

  function testCheckMetadata() public {
    assertEq(abt.name(), "Name");
    assertEq(abt.symbol(), "Symbol");
  }

  function testIfEmptyAddressReturnsBalanceZero() public {
    assertEq(abt.balanceOf(address(1337)), 0);
  }

  function testThrowOnZeroAddress() public {
    vm.expectRevert(bytes("balanceOf: address zero is not a valid owner"));
    abt.balanceOf(address(0));
  }

  function testBalanceIncreaseAfterMint() public {
    address to = msg.sender;
    assertEq(abt.balanceOf(to), 0);
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = 0;
    abt.mint(to, tokenId, tokenURI);
    assertEq(abt.balanceOf(to), 1);
  }

  function testBalanceIncreaseAfterMintAndUnequip() public {
    address to = address(this);
    assertEq(abt.balanceOf(to), 0);
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = 0;
    abt.mint(to, tokenId, tokenURI);
    assertEq(abt.balanceOf(to), 1);
    abt.unequip(tokenId);
    assertEq(abt.balanceOf(to), 0);
  }

  function testMint() public {
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = 0;
    abt.mint(msg.sender, tokenId, tokenURI);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), msg.sender);
  }

  function testMintToExternalAddress() public {
    address thirdparty = address(1337);
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = 0;
    abt.mint(thirdparty, tokenId, tokenURI);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), thirdparty);
  }

  function testMintAndUnequip() public {
    string memory tokenURI = "https://example.com/metadata.json";
    address to = address(this);
    uint256 tokenId = 0;
    abt.mint(to, tokenId, tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    abt.unequip(tokenId);
  }

  function testUnequippingAsNonAuthorizedAccount() public {
    string memory tokenURI = "https://example.com/metadata.json";
    address to = address(this);
    uint256 tokenId = 0;
    abt.mint(to, tokenId, tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
    assertEq(abt.tokenURI(tokenId), tokenURI);

    NonAuthorizedCaller nac = new NonAuthorizedCaller();
    vm.expectRevert(bytes("unequip: sender must be owner"));

    nac.unequip(address(abt), tokenId);
  }

  function testUnequippingNonExistentTokenId() public {
    string memory tokenURI = "https://example.com/metadata.json";
    address to = address(this);
		uint256 tokenId = 0;
    abt.mint(to, tokenId, tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
    assertEq(abt.tokenURI(tokenId), tokenURI);

    NonAuthorizedCaller nac = new NonAuthorizedCaller();
    vm.expectRevert(bytes("ownerOf: token doesn't exist"));

    nac.unequip(address(abt), 1337);
  }

  function testFailToMintTokenToPreexistingTokenId() public {
    string memory tokenURI = "https://example.com/metadata.json";
    uint256 tokenId = 0;
    abt.mint(msg.sender, tokenId, tokenURI);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), msg.sender);
    abt.mint(msg.sender, tokenId, tokenURI);
  }

  function testFailRequestingNonExistentTokenURI() public view {
    abt.tokenURI(1337);
  }

  function testFailGetBonderOfNonExistentTokenId() public view {
    abt.ownerOf(1337);
  }

  function testGiveWithRejectingERC1271Contract() public {
    string memory tokenURI = "https://contenthash.com";
    address from = address(this);
    address to = address(rejecter);
    bytes memory signature;

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = abt.give(
      to,
      tokenURI,
      signature
    );
  }

  function testTakeWithRejectingERC1271Contract() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    address from = address(rejecter);
    bytes memory signature;

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = abt.take(
      from,
      tokenURI,
      signature
    );
  }

  function testGiveWithApprovingERC1271Contract() public {
    string memory tokenURI = "https://contenthash.com";
    address from = address(this);
    address to = address(approver);
    bytes memory signature;

    uint256 tokenId = abt.give(
      to,
      tokenURI,
      signature
    );
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
  }

  function testTakeWithApprovingERC1271Contract() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);
    address from = address(approver);
    bytes memory signature;

    uint256 tokenId = abt.take(
      from,
      tokenURI,
      signature
    );
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
  }

  function testTakeWithDifferentTokenURI() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    string memory falseTokenURI = "https://badstuff.com";
    bytes32 hash = abt.getHash(passiveAddress, to, falseTokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = abt.take(
      passiveAddress,
      tokenURI,
      signature
    );
    assertEq(0, tokenId);
  }

  function testGiveWithDifferentTokenURI() public {
    string memory tokenURI = "https://contenthash.com";
    address from = address(this);
    address to = passiveAddress;

    string memory falseTokenURI = "https://badstuff.com";
    bytes32 hash = abt.getHash(from, to, falseTokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = abt.give(
      to,
      tokenURI,
      signature
    );
    assertEq(0, tokenId);
  }

  function testGiveWithUnauthorizedSender() public {
    string memory tokenURI = "https://contenthash.com";
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = abt.getHash(from, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    address unauthorizedTo = address(1337);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = abt.give(
      unauthorizedTo,
      tokenURI,
      signature
    );
    assertEq(0, tokenId);
  }

  function testTakeWithUnauthorizedSender() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getHash(passiveAddress, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);
    address unauthorizedFrom = address(1337);

    vm.expectRevert(bytes("_safeCheckAgreement: invalid signature"));
    uint256 tokenId = abt.take(
      unauthorizedFrom,
      tokenURI,
      signature
    );
    assertEq(0, tokenId);
  }

  function testGiveEOA() public {
    string memory tokenURI = "https://contenthash.com";
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = abt.getHash(from, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    uint256 tokenId = abt.give(
      to,
      tokenURI,
      signature
    );
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
  }

  function testGiveAndUnequipAndRegive() public {
    string memory tokenURI = "https://contenthash.com";
    address from = address(this);
    address to = address(aa);
    bytes memory signature;

    uint256 tokenId = abt.give(
      to,
      tokenURI,
      signature
    );
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
    aa.unequip(address(abt), tokenId);
    assertEq(abt.balanceOf(to), 0);
    uint256 tokenId2 = abt.give(
      to,
      tokenURI,
      signature
    );
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId2), tokenURI);
    assertEq(abt.ownerOf(tokenId2), to);
  }

  function testTakeAndUnequipAndRetake() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getHash(to, passiveAddress, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    uint256 tokenId = abt.take(
      passiveAddress,
      tokenURI,
      signature
    );
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
    abt.unequip(tokenId);
    assertEq(abt.balanceOf(to), 0);
    uint256 tokenId2 = abt.take(
      passiveAddress,
      tokenURI,
      signature
    );
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId2), tokenURI);
    assertEq(abt.ownerOf(tokenId2), to);
  }

  function testTakeEOA() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getHash(to, passiveAddress, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    uint256 tokenId = abt.take(
      passiveAddress,
      tokenURI,
      signature
    );
    assertEq(abt.balanceOf(to), 1);
    assertEq(abt.tokenURI(tokenId), tokenURI);
    assertEq(abt.ownerOf(tokenId), to);
  }

  function testGiveWithAlreadyUsedVoucher() public {
    string memory tokenURI = "https://contenthash.com";
    address from = address(this);
    address to = passiveAddress;

    bytes32 hash = abt.getHash(from, to, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    abt.give(
      to,
      tokenURI,
      signature
    );

    vm.expectRevert(bytes("_safeCheckAgreement: already used"));
    abt.give(
      to,
      tokenURI,
      signature
    );
  }

  function testTakeWithAlreadyUsedVoucher() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(this);

    bytes32 hash = abt.getHash(to, passiveAddress, tokenURI);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(passivePrivateKey, hash);
    bytes memory signature = abi.encodePacked(r, s, v);

    abt.take(
      passiveAddress,
      tokenURI,
      signature
    );

    vm.expectRevert(bytes("_safeCheckAgreement: already used"));
    abt.take(
      passiveAddress,
      tokenURI,
      signature
    );
  }

  function testPreventGivingToSelf() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(aa);
    address from = address(aa);
    bytes memory signature;

    vm.expectRevert(bytes("give: cannot give from self"));
    aa.give(
      address(abt),
      to,
      tokenURI,
      signature
    );
  }

  function testPreventTakingToSelf() public {
    string memory tokenURI = "https://contenthash.com";
    address to = address(aa);
    address from = address(aa);
    bytes memory signature;

    vm.expectRevert(bytes("take: cannot take from self"));
    aa.take(
      address(abt),
      from,
      tokenURI,
      signature
    );
  }
}

