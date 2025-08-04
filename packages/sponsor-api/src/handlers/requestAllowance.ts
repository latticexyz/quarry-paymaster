import { type } from "arktype";
import { GrantsTable, HexType } from "../common";
import { params } from "./common";
import { decodeErrorResult, formatAbiItemWithArgs, getAction, isHex } from "viem/utils";
import { bundlerClient, getSmartAccountClient, publicClient } from "../clients";
import { sendUserOperation, UserOperationReceipt, waitForUserOperationReceipt } from "viem/account-abstraction";
import { paymaster } from "../contract";
import { debug } from "../debug";
import env from "../env";
import { getRecord } from "@latticexyz/store/internal";
import { Call, Hex, padHex, toHex } from "viem";

/**
 * [receiver: Hex]
 */
const RequestAllowanceInput = type([HexType]);

export async function requestAllowance(rawInput: typeof params.infer) {
  const input = RequestAllowanceInput(rawInput);
  if (input instanceof type.errors) {
    throw new Error(input.summary);
  }

  const [receiver] = input;
  const shouldTrackGrants = Boolean(env.NAMESPACE);

  if (shouldTrackGrants) {
    const existingGrant = await getExistingGrant({ user: receiver });
    if (existingGrant > 0n) {
      throw new Error(`User ${receiver} already received a grant.`);
    }
  }

  const smartAccountClient = await getSmartAccountClient();
  const grantAmount = BigInt(env.ALLOWANCE_AMOUNT);

  const grantAllowanceCall = {
    abi: paymaster.abi,
    to: paymaster.address,
    functionName: "grantAllowance",
    args: [receiver, grantAmount],
  } satisfies Call;

  const trackAllowanceCalls = [
    // Store grant amount
    {
      abi: paymaster.abi,
      to: paymaster.address,
      functionName: "setField",
      args: [
        GrantsTable.tableId,
        [padHex(receiver, { size: 32, dir: "left" })],
        0,
        padHex(toHex(grantAmount), { size: 32, dir: "left" }),
      ],
    },
    // Store last updated timestamp in seconds
    {
      abi: paymaster.abi,
      to: paymaster.address,
      functionName: "setField",
      args: [
        GrantsTable.tableId,
        [padHex(receiver, { size: 32, dir: "left" })],
        1,
        padHex(toHex(Math.floor(Date.now() / 1000)), { size: 4, dir: "left" }),
      ],
    },
  ] satisfies Call[];

  const calls = [grantAllowanceCall, ...(shouldTrackGrants ? trackAllowanceCalls : [])] satisfies Call[];

  debug(`sending user operation to grant allowance to ${receiver}`);
  const hash = await getAction(
    smartAccountClient,
    sendUserOperation,
    "sendUserOperation",
  )({
    calls,
    maxFeePerGas: 100_000n,
    maxPriorityFeePerGas: 0n,
    preVerificationGas: 100_000n,
    verificationGasLimit: 1_000_000n,
    callGasLimit: 1_000_000n,
    paymasterVerificationGasLimit: 100_000n,
    paymasterPostOpGasLimit: 100_000n,
  });

  debug(`waiting for user operation receipt for tx ${hash}`);
  const receipt = await getAction(bundlerClient, waitForUserOperationReceipt, "waitForUserOperationReceipt")({ hash });

  if (!receipt.success) {
    const errorMessage = formatRevertReason(receipt);
    debug(errorMessage);
    throw new Error(errorMessage);
  }

  debug(`successfully granted allowance to ${receiver}`);
  return { message: `Successfully granted allowance to ${receiver}.`, hash };
}

async function getExistingGrant({ user }: { user: Hex }): Promise<bigint> {
  const { amount } = await getRecord(publicClient, {
    table: GrantsTable,
    key: { user },
    address: paymaster.address,
  });
  return amount;
}

function formatRevertReason(receipt: UserOperationReceipt): string {
  if (!isHex(receipt.reason)) {
    return `Failed to grant allowance for an unknown reason.\n\nTransaction hash: ${receipt.receipt.transactionHash}`;
  }

  const reason = decodeErrorResult({ abi: paymaster.abi, data: receipt.reason });

  let output = formatAbiItemWithArgs(reason) + "\n\n";

  if (reason.errorName === "GrantSystem_AllowanceBelowMinimum") {
    output += `Allowance below minimum.`;
    output += "\n\n";
  }

  if (reason.errorName === "GrantSystem_InsufficientBalance") {
    output += `Sponsor balance is not sufficient to grant allowance.`;
    output += "\n\n";
  }

  if (reason.errorName === "GrantSystem_AllowancesLimitReached") {
    output += `User has reached the maximum number of allowances. Remove one and try again.`;
    output += "\n\n";
  }

  return output + `Transaction hash: ${receipt.receipt.transactionHash}`;
}
