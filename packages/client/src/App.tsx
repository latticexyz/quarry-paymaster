import { AccountButton } from "@latticexyz/entrykit/internal";
import { Synced } from "./mud/Synced";
import { useRecords } from "@latticexyz/stash/react";
import { stash } from "./mud/stash";
import { tables } from "./common";
import { useAccount } from "wagmi";
import { useMemo } from "react";

export function App() {
  const account = useAccount();
  const allowances = useRecords({ stash, table: tables.Allowance });
  console.log("Allowances", allowances);
  const receivedAllowances = useMemo(
    () => allowances.filter(({ user }) => user === account.address),
    [allowances, account.address]
  );
  const providedAllowances = useMemo(
    () => allowances.filter(({ sponsor }) => sponsor === account.address),
    [allowances, account.address]
  );

  return (
    <>
      <div className="fixed inset-0 grid place-items-center p-4">
        <Synced
          fallback={({ message, percentage }) => (
            <div className="tabular-nums">
              {message} ({percentage.toFixed(1)}%)…
            </div>
          )}
        >
          <div className="flex flex-row gap-4">
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
        </Synced>
      </div>
      <div className="fixed top-2 right-2">
        <AccountButton />
      </div>
    </>
  );
}
