import { useRecords } from "@latticexyz/stash/react";
import { stash } from "./mud/stash";
import { tables } from "./common";
import { useAccount } from "wagmi";
import { useMemo } from "react";

export function Allowances() {
  const account = useAccount();
  const allowances = useRecords({ stash, table: tables.Allowance });
  const receivedAllowances = useMemo(
    () => allowances.filter(({ user }) => user === account.address),
    [allowances, account.address]
  );
  const providedAllowances = useMemo(
    () => allowances.filter(({ sponsor }) => sponsor === account.address),
    [allowances, account.address]
  );
  console.log("allowances", allowances);

  return (
    <div className="flex flex-col gap-4">
      <div>
        <div>Received</div>
        <div>
          {receivedAllowances.map(({ allowance, sponsor }) => (
            <li key={sponsor}>
              {sponsor}: {allowance.toString()}
            </li>
          ))}
        </div>
      </div>
      <div>
        <div>Provided</div>
        <div>
          {providedAllowances.map(({ allowance, user }) => (
            <li key={user}>
              {user}: {allowance.toString()}
            </li>
          ))}
        </div>
      </div>
    </div>
  );
}
