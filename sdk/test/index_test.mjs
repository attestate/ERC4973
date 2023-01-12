// @format
import test from "ava";

import { Wallet, utils } from "ethers";

import { generateSignature } from "../src/index.mjs";

test("generating a compact signature for function give", async (t) => {
  // from: https://docs.ethers.io/v5/api/signer/#Wallet--methods
  const passiveAddress = "0x0f6A79A579658E401E0B81c6dde1F2cd51d97176";
  const passivePrivateKey =
    "0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39";
  const signer = new Wallet(passivePrivateKey);
  t.is(signer.address, passiveAddress);

  const types = {
    Agreement: [
      { name: "active", type: "address" },
      { name: "passive", type: "address" },
      { name: "metadata", type: "bytes" },
    ],
  };
  const domain = {
    name: "Name",
    version: "Version",
    chainId: 31337, // the chainId of foundry
    verifyingContract: "0x5615deb798bb3e4dfa0139dfa1b3d433cc23b72f",
  };

  const agreement = {
    active: "0x7fa9385be102ac3eac297483dd6233d62b3e1496",
    passive: passiveAddress,
    metadata: utils.toUtf8Bytes("https://example.com/metadata.json"),
  };

  const signature = await generateSignature(signer, types, domain, agreement);
  t.truthy(signature);
  t.is(signature.length, 64 + 64 + 2 + 2);
  t.is(
    signature,
    "0x0e1183b212232b4f1c3e11edd00059fb01710c0335b81c11a43d11d5b7cd01d55483b1a1432f76c4d3cab1bb2607622fd173f8f3d6bdbe8927c4706f9be447321b"
  );
});
