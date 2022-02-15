// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/* Introduction of "Perwei" struct:

  To ensure accounting precising, financial and scientific applications make
  use of a so called "parts-per" notation and so it turns out that: "One part
  per hundred is generally represented by the percent sign (%)" [1].

  But with Solidity and Ethereum having a precision of up to 18 decimal points
  but no native fixed point math arithmetic functions, we have to be careful
  when e.g. calculating fractions of a value.

  E.g. in cases where we want to calculate the tax of a property that's worth
  only 1000 Wei (= 0.000000000000001 Ether) using naive percentages leads to
  inaccuracies when dealing with Solidity's division operator. Hence, libraries
  like solmate and others have come up with "parts-per"-ready implementations
  where values are scaled up. The `Perwei` struct here represents a structure
  of numerator and denominator that allows precise calculations of up to 18
  decimals in the results, e.g. Perwei(1, 1e18).

  References:
  - 1:
https://en.wikipedia.org/w/index.php?title=Parts-per_notation&oldid=1068959843

*/
struct Perwei {
  uint256 numerator;
  uint256 denominator;
}

struct Period {
  uint256 start;
  uint256 end;
}

library Harberger {
  function pay(
    Perwei memory perwei,
    Period memory period,
    uint256 prevPrice
  ) internal view returns (uint256 nextPrice) {
    require(msg.value > 0, "must send eth");
    nextPrice = Harberger.getNextPrice(perwei, period, prevPrice);
    require(msg.value > nextPrice, "msg.value too low");
  }

  function increase(
    Perwei memory perwei,
    Period memory period,
    address owner,
    uint256 prevPrice
  ) internal view returns (uint256 nextPrice) {
    require(msg.value > 0, "must send eth");
    require(owner == msg.sender, "only owner");
    nextPrice = Harberger.getNextPrice(perwei, period, prevPrice) + msg.value;
  }

  function decrease(
    Perwei memory perwei,
    Period memory period,
    uint256 prevPrice,
    address owner,
    uint256 amount
  ) internal view returns (uint256 nextPrice) {
    require(owner != address(0), "owner is zero addr");
    require(owner == msg.sender, "only owner");
    nextPrice = Harberger.getNextPrice(perwei, period, prevPrice) - amount;
  }

  function getNextPrice(
    Perwei memory perwei,
    Period memory period,
    uint256 price
  ) internal pure returns (uint256) {
    uint256 tax = taxPerBlock(perwei, period, price);
    int256 diff = int256(price) - int256(tax);

    if (diff <= 0) {
      return 0;
    } else {
      return uint256(diff);
    }
  }

  function taxPerBlock(
    Perwei memory perwei,
    Period memory period,
    uint256 price
  ) internal pure returns (uint256) {
    uint256 diff = period.end - period.start;
    return FixedPointMathLib.fdiv(
      price * diff * perwei.numerator,
      perwei.denominator * FixedPointMathLib.WAD,
      FixedPointMathLib.WAD
    );
  }
}
