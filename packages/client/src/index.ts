import { adminClient, grantorClient } from "./clients";
import { paymaster } from "./contract";
import { stash } from "./stash";
import { sync } from "./sync";
import { writeContract } from "viem/actions";
import { getAction } from "viem/utils";

async function main() {
  sync();

  getAction(
    adminClient,
    writeContract,
    "writeContract",
  )({
    ...paymaster,
    account: adminClient.account!,
    functionName: "setGrantAllowance",
    args: [grantorClient.account!.address, 1000n],
  });
}

(window as any).stash = stash;
main();
