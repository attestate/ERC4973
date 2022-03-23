// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import {Perwei, Period, Harberger} from "./Harberger.sol";

struct Offer {
  address seller;
  uint256 startBlock;
  uint256 startPrice;
  Perwei taxRate;
  address token;
  uint256 tokenId;
}

contract PluralProperty {
  Offer[] private offers;

  function create(
    Perwei memory taxRate,
    address token,
    uint256 tokenId
  ) external payable returns (uint256) {
    require(msg.value > 0, "must send eth");
    return _create(
      msg.value,
      taxRate,
      token,
      tokenId
    );
  }

  function _create(
    uint256 startPrice,
    Perwei memory taxRate,
    address token,
    uint256 tokenId
  ) internal returns (uint256) {
    Offer memory offer = Offer(
      msg.sender,
      block.number,
      startPrice,
      taxRate,
      token,
      tokenId
    );
    offers.push(offer);
    return offers.length - 1;
  }

  function bid(
    uint256 offerId
  ) external payable returns (uint256) {
    Offer memory offer = offers[offerId];
    require(offer.seller != address(0), "offer doesn't exist");
    uint256 nextPrice = Harberger.pay(
      offer.taxRate,
      Period(offer.startBlock, block.number),
      offer.startPrice
    );

    payable(offer.seller).transfer(nextPrice);
    uint256 nextOfferId = _create(
      msg.value,
      offer.taxRate,
      offer.token,
      offer.tokenId
    );
    return nextOfferId;
  }
}
