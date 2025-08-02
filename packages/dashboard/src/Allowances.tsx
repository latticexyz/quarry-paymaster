import { useRecords } from "@latticexyz/stash/react";
import { stash } from "./mud/stash";
import { tables } from "./common";
import { useAccount } from "wagmi";
import { useMemo } from "react";
import { removeAllowance } from "./removeAllowance";
import { useSessionClient } from "@latticexyz/entrykit/internal";
import { formatEther, Hex } from "viem";
import { AccountName } from "./AccountName";
import { useMutation } from "@tanstack/react-query";
import { twMerge } from "tailwind-merge";

type Props = {
  direction: "received" | "provided";
};

export function Allowances({ direction = "received" }: Props) {
  const account = useAccount();
  const allAllowances = useRecords({ stash, table: tables.Allowance });

  const allowances = useMemo(
    () =>
      allAllowances.filter(
        (allowance) =>
          (direction === "received" && allowance.user === account.address) ||
          (direction === "provided" && allowance.sponsor === account.address)
      ),
    [allAllowances, account.address, direction]
  );

  const { data: sessionClient } = useSessionClient();

  const revoke = useMutation({
    mutationKey: ["revokeAllowance", sessionClient?.uid],
    async mutationFn({ user, sponsor }: { user: Hex; sponsor: Hex }) {
      if (!sessionClient) throw new Error("Not connected.");
      return await removeAllowance({ user, sponsor, client: sessionClient });
    },
  });

  return (
    <div className="flex flex-col gap-4">
      <div>
        <div className="grid grid-cols-[1fr_auto_auto] gap-2 ">
          {allowances.length > 0 ? (
            <>
              <div>{direction === "received" ? "From" : "To"}</div>
              <div>Amount</div>
              <div></div>
            </>
          ) : null}
          {allowances.map(({ allowance, user, sponsor }) => (
            <>
              <div className="text-white">
                <AccountName address={sponsor} />
              </div>
              <div className="text-white">{formatEther(allowance)} ETH</div>
              <button
                type="submit"
                className={twMerge(
                  "group",
                  "bg-neutral-700 hover:brightness-125 active:brightness-90 text-white font-medium cursor-pointer py-1 px-2 text-xs",
                  "disabled:pointer-events-none disabled:opacity-40 disabled:grayscale",
                  "aria-busy:pointer-events-none aria-busy:animate-pulse",
                  "focus:outline-2 focus:outline-blue-400/60"
                )}
                disabled={!sessionClient}
                aria-busy={revoke.isPending}
                onClick={() => revoke.mutate({ user, sponsor })}
              >
                Remove
              </button>
            </>
          ))}
        </div>
      </div>
    </div>
  );
}
