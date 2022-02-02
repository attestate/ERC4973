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
    uint256 price,
    uint256 buffer
  ) internal pure returns (int256 remainder, uint256 nextPrice) {
    uint256 tax = taxPerBlock(percentage, period, price);
    remainder = int256(buffer) - int256(tax);

    if (remainder >= 0) {
      nextPrice = price;
    } else {
      nextPrice = price - uint256(-1*remainder);

      if (nextPrice < 0) {
        nextPrice = 0;
      }
    }

    return (remainder, nextPrice);
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
