import { getAction } from "viem/utils";
import { adminClient, grantorClient, publicClient, smartAccountClient } from "./clients";
import { waitForTransactionReceipt, writeContract } from "viem/actions";
import { paymaster } from "./contract";
import { Address, Hex, parseAbi } from "viem";
import { resourceToHex } from "@latticexyz/common";
import { sendUserOperation } from "viem/account-abstraction";
import { chain } from "./chain";

export async function setGrantAllowance(amount: bigint) {
  const txHash = await getAction(
    adminClient,
    writeContract,
    "writeContract",
  )({
    ...paymaster,
    account: adminClient.account,
    functionName: "setGrantAllowance",
    args: [grantorClient.account!.address, amount],
  });

  const receipt = await waitForTransactionReceipt(publicClient, { hash: txHash });
  console.log("Set grant allowance", receipt);
}

export async function grantAllowance(amount: bigint, receiver: Address) {
  const txHash = await getAction(
    grantorClient,
    writeContract,
    "writeContract",
  )({
    ...paymaster,
    account: grantorClient.account,
    functionName: "grantAllowance",
    args: [receiver, amount],
  });

  const receipt = await waitForTransactionReceipt(publicClient, { hash: txHash });
  console.log("Grant allowance", receipt);
}

export async function registerPass(passId: Hex, claimAmount: bigint, claimInterval: bigint, passValidity: bigint) {
  const txHash = await getAction(
    grantorClient,
    writeContract,
    "writeContract",
  )({
    ...paymaster,
    account: grantorClient.account,
    functionName: "registerPass",
    args: [passId, claimAmount, claimInterval, passValidity],
  });

  const receipt = await waitForTransactionReceipt(publicClient, { hash: txHash });
  console.log("Register pass", receipt);
}

export async function issuePass(passId: Hex, receiver: Address) {
  const txHash = await getAction(
    grantorClient,
    writeContract,
    "writeContract",
  )({
    ...paymaster,
    account: grantorClient.account,
    functionName: "issuePass",
    args: [passId, receiver],
  });

  const receipt = await waitForTransactionReceipt(publicClient, { hash: txHash });
  console.log("Issue pass", receipt);
}

export async function claim(passId: Hex, receiver: Address) {
  const txHash = await getAction(
    grantorClient,
    writeContract,
    "writeContract",
  )({
    ...paymaster,
    // TODO: change to user client once smart account is set up
    account: grantorClient.account,
    functionName: "claimFor",
    args: [receiver, passId],
  });

  const receipt = await waitForTransactionReceipt(publicClient, { hash: txHash });
  console.log("Claim", receipt);
}

export async function registerNamespace(namespace: string) {
  const result = await getAction(
    smartAccountClient,
    sendUserOperation,
    "sendUserOperation",
  )({
    calls: [
      {
        abi: paymaster.abi,
        to: paymaster.address,
        functionName: "registerNamespace",
        args: [resourceToHex({ type: "namespace", namespace, name: "" })],
      },
    ],
    preVerificationGas: 100_000n,
    verificationGasLimit: 1_000_000n,
    callGasLimit: 1_000_000n,
  });

  console.log("Register namespace", result);
}

export async function incrementCounter() {
  if (!("counter" in chain.contracts)) {
    console.log("counter not supported on this chain");
    return;
  }

  const result = await getAction(
    smartAccountClient,
    sendUserOperation,
    "sendUserOperation",
  )({
    calls: [
      {
        abi: parseAbi(["function increment() returns (uint256)"]),
        to: chain.contracts.counter.address,
        functionName: "increment",
        args: [],
      },
    ],
    preVerificationGas: 100_000n,
    verificationGasLimit: 1_000_000n,
    callGasLimit: 1_000_000n,
  });

  console.log("Increment counter", result);
}
