<p align="center">
  <img src="/assets/harbergerschema.jpg" />
</p>

### A dapptools-ready library for charging Harberger taxes on non-fungible property.
#### [Installation](readme.md/#Installation) | [License](readme.md#License) | [Usage](readme.md#Usage)

## Installation

```bash
dapp install rugpullindex/libharberger
```

## Usage

```sol
pragma solidity ^0.8.6;

import {Harberger, Period, Perwei} from "libharberger/Harberger.sol";

function tax() pure {
  uint256 price = 1 ether;

  Period period = Period(0, block.number);
  Perwei taxRate = Perwei(1, 100) // == 0.01
  uint256 nextPrice = Harberger.getNextPrice(taxRate, period, price);

  //...
}
```

## Caveats & Mechanic

An actual implementation of a Harberger tax would include charging a property
owner a tax rate periodically e.g. every month. In, let's say, the traditional
banking system: that'd mean the property owner transfers the tax in a
transaction monthly. The spiritual predecessor of this library
[bin-studio/harberger-ads-contracts](https://github.com/bin-studio/harberger-ads-contracts)
indeed implemented a
[`collectTaxes`](https://github.com/bin-studio/harberger-ads-contracts/blob/6f2d61e75afd2b3efb31e8e9e95395e93b11a80a/contracts/HarbergerAds.sol#L73)
method that's supposed to be called periodically by the contract operator.

However, as since then gas prices on Ethereum mainnet have increased
significantly and as periodically calling functions seems wastful, we're
implementing the Harberger tax as a periodically reduced price value.

Say you buy property X for price `p_x = 1 ether` at block `b_x`, where `x = 0`,
then for each block `b_x+1` we reduce `p_x+1` by the tax rate. If say the tax
rate was `t = 0.01`, then property X price at block 1 
`b_1` is `p_1 = 1 ether - 1 ether * 0.01 = 0.99 ether` and at 
`b_2`, `p_2 = 0.99 ether - 0.99 ether * 0.01 = 0.9801 ether` and so on.

We decrease the price in that way until it reaches zero, for when a new buyer
can buy the property for free. By taxing this way, we don't need to
periodically call a `collectTaxes` method.

## Changelog

### 0.3.0

- Rename `Percentage` struct to `Perwei`
- Add further tests to confirm precision of up to 18 decimal points

NOTE: We only noticed now that between 0.0.1 and 0.2.0, we've made a mistake in
semantic versioning as "0.2.0" should actually be "0.1.0". But we're deciding
to stick with the mistake and we'll try to properly produce ascending numbers
in the future.

### 0.2.0

- Simplify pricing mechanism

### 0.0.1

- Initial release

## License

See LICENSE file.
