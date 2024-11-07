import { type } from "arktype";
import { HexType } from "../common";
import { params } from "./common";
import { decodeErrorResult, formatAbiItemWithArgs, getAction, isHex, padHex, toHex } from "viem/utils";
import { bundlerClient, getSmartAccountClient } from "../clients";
import { sendUserOperation, UserOperationReceipt, waitForUserOperationReceipt } from "viem/account-abstraction";
import { paymaster } from "../contract";
import { debug } from "../debug";

/**
 * [passId: Hex, receiver: Hex]
 */
const IssuePassInput = type([HexType, HexType]);

export async function issuePass(rawInput: typeof params.infer) {
  const input = IssuePassInput(rawInput);
  if (input instanceof type.errors) {
    throw new Error(input.summary);
  }

  const smartAccountClient = await getSmartAccountClient();

  const [passId, receiver] = input;
  debug(`sending user operation to issue pass ${passId} to ${receiver}`);
  const hash = await getAction(
    smartAccountClient,
    sendUserOperation,
    "sendUserOperation",
  )({
    calls: [
      {
        abi: paymaster.abi,
        to: paymaster.address,
        functionName: "issuePass",
        args: [padHex(passId), receiver],
      },
    ],
    maxFeePerGas: 100_000n,
    maxPriorityFeePerGas: 0n,
    preVerificationGas: 100_000n,
    verificationGasLimit: 1_000_000n,
    callGasLimit: 1_000_000n,
  });

  debug(`waiting for user operation receipt for tx ${hash}`);
  const receipt = await getAction(bundlerClient, waitForUserOperationReceipt, "waitForUserOperationReceipt")({ hash });

  if (!receipt.success) {
    const errorMessage = formatRevertReason(receipt);
    debug(errorMessage);
    throw new Error(errorMessage);
  }

  debug(`successfully issued pass ${passId} to ${receiver}`);
  return { message: `Successfully issued pass ${passId} to ${receiver}.`, hash };
}

function formatRevertReason(receipt: UserOperationReceipt): string {
  if (!isHex(receipt.reason)) {
    return `Failed to issue pass for an unknown reason.\n\nTransaction hash: ${receipt.receipt.transactionHash}`;
  }

  const reason = decodeErrorResult({ abi: paymaster.abi, data: receipt.reason });

  let output = formatAbiItemWithArgs(reason) + "\n\n";

  if (reason.errorName === "PassSystem_Unauthorized") {
    output +=
      reason.args[2] === toHex("", { size: 20 })
        ? `Pass ${reason.args[0]} does not exist.`
        : `Caller ${reason.args[1]} is not authorized to issue pass ${reason.args[0]}.`;
    output += "\n\n";
  }

  return output + `Transaction hash: ${receipt.receipt.transactionHash}`;
}
