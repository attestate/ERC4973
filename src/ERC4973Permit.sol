// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

abstract contract ERC4973Permit is EIP712 {
    error ErrorUnauthorizedMinting();

    bytes32 private constant MINT_PERMIT_TYPEHASH =
        keccak256(
            "MintPermit(address from,address to,string tokenURI)"
        );

    constructor(string memory name) EIP712(name, "1") {}

    function _getMintPermitMessageHash(
        address from,
        address to,
        string memory tokenURI
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(MINT_PERMIT_TYPEHASH, from, to, tokenURI)
        );

        return _hashTypedDataV4(structHash);
    }

    function _isPermittedToMint(
        address from,
        address to,
        string memory tokenURI,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 mintPermitHash = _getMintPermitMessageHash(
            from,
            to,
            tokenURI
        );

        address approver = ECDSA.recover(mintPermitHash, v, r, s);

        return approver == from;
    }
}
