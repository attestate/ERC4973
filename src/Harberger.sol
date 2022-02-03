// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

struct Percentage {
  uint256 numerator;
  uint256 denominator;
}

struct Period {
  uint256 start;
  uint256 end;
}

library Harberger {
  function getNextPrice(
    Percentage memory percentage,
    Period memory period,
    uint256 price
  ) internal pure returns (uint256) {
    uint256 tax = taxPerBlock(percentage, period, price);
    int256 diff = int256(price) - int256(tax);

    if (diff <= 0) {
      return 0;
    } else {
      return uint256(diff);
    }
  }

  function taxPerBlock(
    Percentage memory percentage,
    Period memory period,
    uint256 price
  ) internal pure returns (uint256) {
    uint256 diff = period.end - period.start;
    return FixedPointMathLib.fdiv(
      price * diff * percentage.numerator,
      percentage.denominator * FixedPointMathLib.WAD,
      FixedPointMathLib.WAD
    );
  }
}
