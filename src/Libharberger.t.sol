// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./Libharberger.sol";

contract LibharbergerTest is DSTest {
    Libharberger libharberger;

    function setUp() public {
        libharberger = new Libharberger();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
