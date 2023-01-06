# Changelog

## 0.5.0

- Removed EIP-2098 support as EIP-1271 expects a "naively" concatenated
  signature and not an EIP-2098-style compact signature. This was pushed
  upstream with @frangio removing support for EIP-2098 in the
  `SignatureChecker` library.
- Change `string tokenURI` in structure data hash and `give` and `take` inputs
  to a more generic `bytes metadata`. PR:
  https://github.com/attestate/ERC4973/pull/52
- Start using `forge fmt` for all Solidity code formatting

## 0.4.0

- Comply with standard specification at:
  https://github.com/ethereum/EIPs/tree/c27955426935d9aaee42c085f36e27f7e71c78f4
- Add `sdk/src/index.js` to generating valid EIP-721 signatures for `function take` and `function give`.
- Index more files in `package.json` such that hardhat users can import
  Solidity code properly.
- Correctly pass `from` to `Transfer(from, to, id)` in mint and not permanently
  use `address(0)`, thx @rahulrumalla.
- Remove ascending `tokenId` and instead generate it from the typed data hash.
- Improve function NATSPEC

## 0.3.0

- Comply with standard specification at:
  https://github.com/ethereum/EIPs/tree/96a91604a547781a596de6af4cb22ec60c4601db
- Generate ERC4973-flat.sol automatically via GitHub Actions
- Pin Solidity 0.8.8

## 0.2.0

- Comply with standard specification at:
  https://github.com/ethereum/EIPs/tree/3c27220b55928d358da972184aeeedd3ec95f68e

## 0.1.0

- Comply with standard specification at:
  https://github.com/ethereum/EIPs/tree/78bc7a8ecc0bea3c73e21a43258e4de5748afbfc

## 0.0.2

- Comply with standard specification at:
  https://github.com/ethereum/EIPs/tree/d5858d249ffbdab2e39bc56026366682678704dd

## 0.0.1

- Initial release
