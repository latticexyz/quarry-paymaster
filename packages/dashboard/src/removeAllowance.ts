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

type RemoveAllowanceInput = {
  user: Hex;
  sponsor: Hex;
  client: SessionClient;
};

export async function removeAllowance({
  user,
  sponsor,
  client,
}: RemoveAllowanceInput) {
  debug(
    `sending user operation to remove allowance for ${user} from ${sponsor}`
  );
  const hash = await getAction(
    client,
    sendUserOperation,
    "sendUserOperation"
  )({
    calls: [
      {
        abi: paymasterAbi,
        to: getWorldAddress(),
        functionName: "removeAllowance",
        args: [user, sponsor],
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

  debug(`successfully removed allowance for ${user} from ${sponsor}`);
  return {
    message: `Successfully removed allowance for ${user} from ${sponsor}.`,
    hash,
  };
}

function formatRevertReason(receipt: UserOperationReceipt): string {
  if (!isHex(receipt.reason)) {
    return `Failed to remove allowance for an unknown reason.\n\nTransaction hash: ${receipt.receipt.transactionHash}`;
  }

  const reason = decodeErrorResult({
    abi: paymasterAbi,
    data: receipt.reason,
  });

  let output = formatAbiItemWithArgs(reason) + "\n\n";

  if (reason.errorName === "AllowanceSystem_NotAuthorized") {
    output += `Not authorized to remove allowance.`;
    output += "\n\n";
  }

  return output + `Transaction hash: ${receipt.receipt.transactionHash}`;
}
