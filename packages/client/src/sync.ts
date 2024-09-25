import { publicClient } from "./clients";
import { stash } from "./stash";
import worldDeployment from "contracts/deploys/31337/latest.json";
import { syncToStash, SyncToStashResult } from "@latticexyz/store-sync/internal";
import { Hex } from "viem";

export async function sync(): Promise<SyncToStashResult> {
  return syncToStash({
    stash,
    publicClient,
    address: worldDeployment.worldAddress as Hex,
    startBlock: BigInt(worldDeployment.blockNumber),
  });
}
