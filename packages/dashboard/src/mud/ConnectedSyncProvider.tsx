import { SyncProvider } from "@latticexyz/store-sync/react";
import { chainId, getWorldAddress, tables, startBlock } from "../common";
import { ReactNode } from "react";
import { createSyncAdapter } from "@latticexyz/store-sync/internal";
import { stash } from "./stash";
import { useAccount } from "wagmi";
import { AccountButton } from "@latticexyz/entrykit/internal";
import { Hex, padHex } from "viem";
import { encodeKey } from "@latticexyz/stash/internal";

export type Props = {
  children: ReactNode;
};

export function ConnectedSyncProvider({ children }: Props) {
  const worldAddress = getWorldAddress();
  const user = useAccount();
  console.log("user", user.address);

  if (!user.address) {
    return (
      <div className="fixed inset-0 grid place-items-center p-4">
        <div className="text-center">
          <div className="pb-4">Connect your wallet to continue</div>
          <AccountButton />
        </div>
      </div>
    );
  }

  const userKey = padHex(user.address, { dir: "left", size: 32 });
  console.log("userKey", userKey);

  return (
    <SyncProvider
      chainId={chainId}
      address={worldAddress}
      startBlock={startBlock}
      adapter={createSyncAdapter({ stash })}
      filters={[
        {
          tableId: tables.Balance.tableId,
        },
        {
          tableId: tables.Allowance.tableId,
        },
      ]}
    >
      {children}
    </SyncProvider>
  );
}
