import { getAction, parseEther } from "viem/utils";
import { adminClient, grantorClient, publicClient, smartAccountClient, userClient } from "./clients";
import { waitForTransactionReceipt, writeContract } from "viem/actions";
import { paymaster } from "./contract";
import { Address, Hex } from "viem";
import { resourceToHex } from "@latticexyz/common";

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

export async function registerPass(passId: Hex) {
  const claimAmount = parseEther("0.01");
  const claimInterval = 5n;
  const validityPeriod = 30n;

  const txHash = await getAction(
    grantorClient,
    writeContract,
    "writeContract",
  )({
    ...paymaster,
    account: grantorClient.account,
    functionName: "registerPass",
    args: [passId, claimAmount, claimInterval, validityPeriod],
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
  const txHash = await getAction(
    smartAccountClient,
    writeContract,
    "writeContract",
  )({
    ...paymaster,
    account: smartAccountClient.account,
    functionName: "registerNamespace",
    args: [resourceToHex({ type: "namespace", namespace, name: "" })],
  });

  const receipt = await waitForTransactionReceipt(publicClient, { hash: txHash });
  console.log("Register namespace", receipt);
}
