// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import {DSTest} from "ds-test/test.sol";

import {Harberger} from "./Harberger.sol";

contract HarbergerTest is DSTest {
    function testBlockTax() public {
      assertEq(tax(0, 50, 1 ether), 0.5 ether);
      assertEq(tax(0, 1, 1 ether), 0.01 ether);
    }
}
