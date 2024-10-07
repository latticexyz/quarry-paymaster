import { type } from "arktype";
import { HexType } from "../common";
import { params } from "./common";
import { getAction, padHex } from "viem/utils";
import { publicClient, getSmartAccountClient } from "../clients";
import { sendUserOperation, waitForUserOperationReceipt } from "viem/account-abstraction";
import { paymaster } from "../contract";

/**
 * [receiver: Hex, passId: Hex]
 */
const ClaimAllowanceInput = type([HexType, HexType]);

export async function claimAllowance(rawInput: typeof params.infer) {
  const input = ClaimAllowanceInput(rawInput);
  if (input instanceof type.errors) {
    throw new Error(input.summary);
  }

  const [receiver, passId] = input;
  console.log("failed before sending");
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
  console.log("Waiting for user operation request", hash);
  const result = await waitForUserOperationReceipt(publicClient, { hash });

  if (!result.success) {
    throw new Error(`Failed to claim allowance for ${receiver} from pass ${passId}`);
  }

  return { message: `Successfully claimed allowance for ${receiver} from pass ${passId}.` };
}
