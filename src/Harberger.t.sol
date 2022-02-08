// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";

import {Harberger, Period, Perwei} from "./Harberger.sol";

contract HarbergerTest is DSTest {
    function testPriceZero() public {
      Period memory period1 = Period(0, 50);
      Perwei memory perwei1 = Perwei(100, 100);

      uint256 price = 0;
      uint256 nextPrice = Harberger.getNextPrice(
        perwei1,
        period1,
        price
      );
      assertEq(nextPrice, 0);
    }

    function testUsedBuffer() public {
      Period memory period1 = Period(0, 50);
      Perwei memory perwei1 = Perwei(1, 100);
      uint256 price = 1 ether;

      uint256 nextPrice = Harberger.getNextPrice(
        perwei1,
        period1,
        price
      );
      assertEq(nextPrice, 0.5 ether);
    }

    function testLowerPrice() public {
      Period memory period1 = Period(0, 51);
      Perwei memory perwei1= Perwei(1, 100);
      uint256 price = 1 ether;

      uint256 nextPrice = Harberger.getNextPrice(
        perwei1,
        period1,
        price
      );
      assertEq(nextPrice, 0.49 ether);
    }

    function testConsumingTotalPrice() public {
      Period memory period1 = Period(0, 150);
      Perwei memory perwei1 = Perwei(1, 100);
      uint256 price = 1 ether;

      uint256 nextPrice = Harberger.getNextPrice(
        perwei1,
        period1,
        price
      );
      assertEq(nextPrice, 0);
    }

    function testGettingNextPrice() public {
      Period memory period1 = Period(0, 1);
      Perwei memory perwei1 = Perwei(1, 100);
      uint256 price = 1 ether;

      uint256 nextPrice = Harberger.getNextPrice(
        perwei1,
        period1,
        price
      );
      assertEq(nextPrice, 0.99 ether);
    }

    function testBlockTax() public {
      Period memory period1 = Period(0, 1);
      Perwei memory perwei1 = Perwei(1, 100);
      assertEq(Harberger.taxPerBlock(perwei1, period1, 1 ether), 0.01 ether);

      Period memory period2 = Period(0, 2);
      Perwei memory perwei2 = Perwei(1, 100);
      assertEq(Harberger.taxPerBlock(perwei2, period2, 1 ether), 0.02 ether);

      Period memory period3 = Period(0, 100);
      Perwei memory perwei3 = Perwei(1, 100);
      assertEq(Harberger.taxPerBlock(perwei3, period3, 1 ether), 1 ether);

      Period memory period4 = Period(0, 2);
      Perwei memory perwei4 = Perwei(100, 100);
      assertEq(Harberger.taxPerBlock(perwei4, period4, 1 ether), 2 ether);

      Period memory period5 = Period(0, 1);
      Perwei memory perwei5 = Perwei(1, 1000);
      assertEq(Harberger.taxPerBlock(perwei5, period5, 1 ether), 0.001 ether);

      Period memory period6 = Period(0, 1);
      // NOTE: To test the precision up to 18 decimals, we're gonna simulate a
      // tax that is 1 WEI per block.
      Perwei memory perwei6 = Perwei(1, 1e18);
      assertEq(Harberger.taxPerBlock(perwei6, period6, 1 ether), 1 wei);
    }
}
