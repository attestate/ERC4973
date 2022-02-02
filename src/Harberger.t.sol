// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";

import {Harberger, Period, Percentage} from "./Harberger.sol";

contract HarbergerTest is DSTest {
    function testPriceZero() public {
      Period memory period1 = Period(0, 50);
      Percentage memory percentage1 = Percentage(100, 100);

      uint256 price = 0;
      uint256 buffer = 0;
      (int256 remainder, uint256 nextPrice) = Harberger.getNextPrice(
        percentage1,
        period1,
        price,
        buffer
      );
      assertEq(remainder, 0);
      assertEq(nextPrice, 0);
    }

    function testUsedBuffer() public {
      Period memory period1 = Period(0, 50);
      Percentage memory percentage1 = Percentage(1, 100);
      uint256 price = 1 ether;
      uint256 buffer = 0.5 ether;

      (int256 remainder, uint256 nextPrice) = Harberger.getNextPrice(
        percentage1,
        period1,
        price,
        buffer
      );
      assertEq(remainder, 0);
      assertEq(nextPrice, 1 ether);
    }

    function testLowerPrice() public {
      Period memory period1 = Period(0, 51);
      Percentage memory percentage1 = Percentage(1, 100);
      uint256 price = 1 ether;
      uint256 buffer = 0.5 ether;

      (int256 remainder, uint256 nextPrice) = Harberger.getNextPrice(
        percentage1,
        period1,
        price,
        buffer
      );
      assertEq(remainder, -0.01 ether);
      assertEq(nextPrice, 0.99 ether);
    }

    function testConsumingTotalPrice() public {
      Period memory period1 = Period(0, 150);
      Percentage memory percentage1 = Percentage(1, 100);
      uint256 price = 1 ether;
      uint256 buffer = 0.5 ether;

      (int256 remainder, uint256 nextPrice) = Harberger.getNextPrice(
        percentage1,
        period1,
        price,
        buffer
      );
      assertEq(remainder, -1 ether);
      assertEq(nextPrice, 0);
    }

    function testGettingNextPrice() public {
      Period memory period1 = Period(0, 1);
      Percentage memory percentage1 = Percentage(1, 100);
      uint256 price = 1 ether;
      uint256 buffer = 0.5 ether;

      (int256 remainder, uint256 nextPrice) = Harberger.getNextPrice(
        percentage1,
        period1,
        price,
        buffer
      );
      assertEq(remainder, 0.49 ether);
      assertEq(nextPrice, 1 ether);
    }

    function testBlockTax() public {
      Period memory period1 = Period(0, 1);
      Percentage memory percentage1 = Percentage(1, 100);
      assertEq(Harberger.taxPerBlock(percentage1, period1, 1 ether), 0.01 ether);

      Period memory period2 = Period(0, 2);
      Percentage memory percentage2 = Percentage(1, 100);
      assertEq(Harberger.taxPerBlock(percentage2, period2, 1 ether), 0.02 ether);

      Period memory period3 = Period(0, 100);
      Percentage memory percentage3 = Percentage(1, 100);
      assertEq(Harberger.taxPerBlock(percentage3, period3, 1 ether), 1 ether);

      Period memory period4 = Period(0, 2);
      Percentage memory percentage4 = Percentage(100, 100);
      assertEq(Harberger.taxPerBlock(percentage4, period4, 1 ether), 2 ether);
    }
}
