import { type } from "arktype";
import { HexType } from "../common";
import { params } from "./common";
import { decodeErrorResult, formatAbiItemWithArgs, getAction, isHex } from "viem/utils";
import { bundlerClient, getSmartAccountClient } from "../clients";
import { sendUserOperation, UserOperationReceipt, waitForUserOperationReceipt } from "viem/account-abstraction";
import { paymaster } from "../contract";
import { debug } from "../debug";
import env from "../env";

/**
 * [receiver: Hex]
 */
const RequestAllowanceInput = type([HexType]);

export async function requestAllowance(rawInput: typeof params.infer) {
  const input = RequestAllowanceInput(rawInput);
  if (input instanceof type.errors) {
    throw new Error(input.summary);
  }

  const smartAccountClient = await getSmartAccountClient();

  const [receiver] = input;
  debug(`sending user operation to grant allowance to ${receiver}`);
  const hash = await getAction(
    smartAccountClient,
    sendUserOperation,
    "sendUserOperation",
  )({
    calls: [
      {
        abi: paymaster.abi,
        to: paymaster.address,
        functionName: "grantAllowance",
        args: [receiver, BigInt(env.ALLOWANCE_AMOUNT)],
      },
    ],
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

function formatRevertReason(receipt: UserOperationReceipt): string {
  if (!isHex(receipt.reason)) {
    return `Failed to grant allowance for an unknown reason.\n\nTransaction hash: ${receipt.receipt.transactionHash}`;
  }

  const reason = decodeErrorResult({ abi: paymaster.abi, data: receipt.reason });

  let output = formatAbiItemWithArgs(reason) + "\n\n";

  if (reason.errorName === "AllowanceSystem_AllowanceBelowMinimum") {
    output += `Allowance below minimum.`;
    output += "\n\n";
  }

  if (reason.errorName === "AllowanceSystem_InsufficientBalance") {
    output += `Sponsor balance is not sufficient to grant allowance.`;
    output += "\n\n";
  }

  if (reason.errorName === "AllowanceSystem_AllowancesLimitReached") {
    output += `User has reached the maximum number of allowances. Remove one and try again.`;
    output += "\n\n";
  }

  return output + `Transaction hash: ${receipt.receipt.transactionHash}`;
}
