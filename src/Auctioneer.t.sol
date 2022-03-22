// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";

import {Auctioneer} from "./Auctioneer.sol";
import {Perwei} from "./Harberger.sol";

contract AuctioneerTest is DSTest {
  Auctioneer a;

  function setUp() public {
    a = new Auctioneer();
  }
  receive() external payable {}

  function testBidOnAnOffer() public {
    uint256 startBlock = block.number;
    uint256 startPrice = 1 ether;
    Perwei memory taxRate = Perwei(1, 100);
    address token = address(1);
    uint256 tokenId = 0;
    uint256 offerId0 = a.create{value: startPrice}(
      taxRate,
      token,
      tokenId
    );

    uint256 firstBalance = address(this).balance;
    a.bid{value: 1.1 ether}(offerId0);
    uint256 secondBalance = address(this).balance;
    uint256 endBlock = block.number;
    assertEq(endBlock-startBlock, 0);
    assertEq(firstBalance-secondBalance, 0.1 ether);
    assertEq(address(a).balance, 1.1 ether);
  }

  function testFailBidWithFalsePrice() public {
    uint256 startPrice = 1 ether;
    Perwei memory taxRate = Perwei(1, 100);
    address token = address(1);
    uint256 tokenId = 0;
    uint256 offerId0 = a.create{value: startPrice}(
      taxRate,
      token,
      tokenId
    );

    a.bid{value: 0.1 ether}(offerId0);
  }

  function testFailBidOnNonExistentOffer() public {
    a.bid(1337);
  }

  function testFailCreateOfferWithoutValue() public {
    Perwei memory taxRate = Perwei(1, 100);
    address token = address(1);
    uint256 tokenId = 0;
    a.create{value: 0}(
      taxRate,
      token,
      tokenId
    );
  }

  function testCreateOffer() public {
    uint256 startPrice = 1 ether;
    Perwei memory taxRate = Perwei(1, 100);
    address token = address(1);
    uint256 tokenId = 0;
    uint256 offerId0 = a.create{value: startPrice}(
      taxRate,
      token,
      tokenId
    );
    assertEq(offerId0, 0);
    uint256 offerId1 = a.create{value: startPrice}(
      taxRate,
      token,
      tokenId
    );
    assertEq(offerId1, 1);
  }
}

