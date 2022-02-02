// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";

import {Harberger, Period, Percentage} from "./Harberger.sol";

contract HarbergerTest is DSTest {
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
