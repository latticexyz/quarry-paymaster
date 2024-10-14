import { type } from "arktype";
import { HexType } from "../common";
import { params } from "./common";
import { decodeErrorResult, formatAbiItemWithArgs, getAction, isHex, padHex } from "viem/utils";
import { getSmartAccountClient, bundlerClient } from "../clients";
import { sendUserOperation, UserOperationReceipt, waitForUserOperationReceipt } from "viem/account-abstraction";
import { paymaster } from "../contract";
import { debug, error } from "../debug";

/**
 * [passId: Hex, receiver: Hex]
 */
const ClaimAllowanceInput = type([HexType, HexType]);

export async function claimAllowance(rawInput: typeof params.infer) {
  const input = ClaimAllowanceInput(rawInput);
  if (input instanceof type.errors) {
    throw new Error(input.summary);
  }

  const [passId, receiver] = input;
  debug(`sending user operation to claim allowance from pass ${passId} for ${receiver}`);
  const hash = await getAction(
    await getSmartAccountClient(),
    sendUserOperation,
    "sendUserOperation",
  )({
    calls: [
      {
        abi: paymaster.abi,
        to: paymaster.address,
        functionName: "claimFor",
        args: [receiver, padHex(passId)],
      },
    ],
    preVerificationGas: 100_000n,
    verificationGasLimit: 1_000_000n,
    callGasLimit: 1_000_000n,
  });

  debug(`waiting for user operation receipt for tx ${hash}`);
  const receipt = await waitForUserOperationReceipt(bundlerClient, { hash });

  if (!receipt.success) {
    const errorMessage = formatRevertReason(receipt);
    debug(errorMessage);
    throw new Error(errorMessage);
  }

  debug(`successfully issued pass ${passId} to ${receiver}`);
  return { message: `Successfully claimed allowance for ${receiver} from pass ${passId}.` };
}

function formatRevertReason(receipt: UserOperationReceipt): string {
  if (!isHex(receipt.reason)) {
    return `Failed to claim allowance for an unknown reason.\n\nTransaction hash: ${receipt.receipt.transactionHash}`;
  }

  const reason = decodeErrorResult({ abi: paymaster.abi, data: receipt.reason });

  let output = formatAbiItemWithArgs(reason) + "\n\n";

  if (reason.errorName === "PassSystem_PendingCooldown") {
    output += `Next time user ${reason.args[2]} can claim from pass ${reason.args[0]} is ${new Date(Number(reason.args[3] + reason.args[1]) * 1000).toUTCString()}.\n\n`;
  }

  if (reason.errorName === "PassSystem_PassExpired") {
    output +=
      reason.args[3] === 0n
        ? `User ${reason.args[2]} doesn't have pass ${reason.args[0]}.\n\n`
        : `User ${reason.args[2]}'s pass ${reason.args[0]} expired on ${new Date(Number(reason.args[3] + reason.args[1]) * 1000).toUTCString()}.\n\n`;
  }

  if (reason.errorName === "PassSystem_InsufficientGrantorAllowance") {
    output += `Grantor ${reason.args[1]} ran out of grant allowance.\n\n`;
  }

  return output + `Transaction hash: ${receipt.receipt.transactionHash}`;
}
