import { formatEther, getAction, padHex, parseEther } from "viem/utils";
import { adminClient, grantorClient, publicClient, userClient } from "./clients";
import { waitForTransactionReceipt, writeContract } from "viem/actions";
import { paymaster } from "./contract";
import { Hex } from "viem";

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

export async function grantAllowance(amount: bigint) {
  const txHash = await getAction(
    grantorClient,
    writeContract,
    "writeContract",
  )({
    ...paymaster,
    account: grantorClient.account,
    functionName: "grantAllowance",
    args: [userClient.account.address, amount],
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

export async function issuePass(passId: Hex) {
  const txHash = await getAction(
    grantorClient,
    writeContract,
    "writeContract",
  )({
    ...paymaster,
    account: grantorClient.account,
    functionName: "issuePass",
    args: [passId, userClient.account.address],
  });

  const receipt = await waitForTransactionReceipt(publicClient, { hash: txHash });
  console.log("Issue pass", receipt);
}

export async function claim(passId: Hex) {
  const txHash = await getAction(
    grantorClient,
    writeContract,
    "writeContract",
  )({
    ...paymaster,
    // TODO: change to user client once smart account is set up
    account: grantorClient.account,
    functionName: "claimFor",
    args: [userClient.account.address, passId],
  });

  const receipt = await waitForTransactionReceipt(publicClient, { hash: txHash });
  console.log("Claim", receipt);
}
