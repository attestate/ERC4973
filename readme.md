# ERC4973 - Account-bound tokens

Testable implementation of
[EIP-4973](https://eips.ethereum.org/EIPS/eip-4973).

GitHub Actions is continuously building the flat file reference implementation
to [assets/ERC4973-flat.sol](https://github.com/attestate/ERC4973/blob/master/assets/ERC4973-flat.sol)

## Communication

- Non-formal communication can happen across all communication channels, e.g.,
  our ["Account-bound token" TG channel](https://t.me/eip4973)
- A lot of discussion about "Soulbound tokens" is happening on the
  [RadicalExchange](https://www.radicalxchange.org/) Discord server.
- [Otterspace](https://www.otterspace.xyz/) is committing a significant portion
  of their current product iteration towards integrating the standard. So is
  [violet.co](https://violet.co/).
- However, for any formal communication regarding the standard document, make
  sure you leave a comment on the [official discussion thread on the Ethereum
  Magicians
  forum](https://ethereum-magicians.org/t/eip-4973-account-bound-tokens/8825)!
  It is vital to appropriately document community sentiment and interest.
  Thanks!

## Finding the right version

- EIP-4973 is in "[DRAFT](https://eips.ethereum.org/EIPS/eip-1#eip-process)"
  phase currently. Changes MIGHT happen and the interface is still unstable.
  Please take this into consideration before you start building on the
  interface.
- Still, we want to give everyone a chance to upgrade cooperatively using
  [semver](https://semver.org/). In [changelog.md](./changelog.md) each git tag
  will have a respective description, e.g., referrencing the ethereum/EIPs
  commit height we're implementing.

## Installation with foundry/dapptools

```bash
forge install https://github.com/attestate/ERC4973
dapp install https://github.com/attestate/ERC4973
```

## Installation with npm

```bash
npm i erc4973
```

## Contributing

Please reach out to me e.g. on social media or via emails, I can get you
started.. Alternatively check the [official feedback
thread](https://ethereum-magicians.org/t/eip-4973-account-bound-tokens/8825) on
the Ethereum Magician's forum.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
