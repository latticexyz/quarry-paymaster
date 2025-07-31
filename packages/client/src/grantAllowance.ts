import { getWorldAddress } from "./common";
import {
  decodeErrorResult,
  formatAbiItemWithArgs,
  getAction,
  isHex,
} from "viem/utils";
import {
  sendUserOperation,
  UserOperationReceipt,
  waitForUserOperationReceipt,
} from "viem/account-abstraction";
import { debug } from "./debug";
import { Hex } from "viem";
import { SessionClient } from "@latticexyz/entrykit/internal";
import paymasterAbi from "contracts/out/IWorld.sol/IWorld.abi.json";

type GrantAllowanceInput = {
  receiver: Hex;
  allowance: bigint;
  client: SessionClient;
};

export async function grantAllowance({
  receiver,
  allowance,
  client,
}: GrantAllowanceInput) {
  debug(`sending user operation to grant allowance to ${receiver}`);
  const hash = await getAction(
    client,
    sendUserOperation,
    "sendUserOperation"
  )({
    calls: [
      {
        abi: paymasterAbi,
        to: getWorldAddress(),
        functionName: "grantAllowance",
        args: [receiver, allowance],
      },
    ],
  });

  debug(`waiting for user operation receipt for tx ${hash}`);
  const receipt = await getAction(
    client,
    waitForUserOperationReceipt,
    "waitForUserOperationReceipt"
  )({ hash });

  console.log("user operation receipt", receipt);
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

  const reason = decodeErrorResult({
    abi: paymasterAbi,
    data: receipt.reason,
  });

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
