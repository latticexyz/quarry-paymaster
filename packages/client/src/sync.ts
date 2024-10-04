import { publicClient } from "./clients";
import { stash } from "./stash";
import worlds from "contracts/worlds.json";
import { syncToStash, SyncToStashResult } from "@latticexyz/store-sync/internal";
import { chain } from "./chain";

export async function sync(): Promise<SyncToStashResult> {
  return syncToStash({
    stash,
    publicClient,
    address: worlds[chain.id]!.address,
    startBlock: BigInt(worlds[chain.id]?.blockNumber ?? 0n),
  });
}
