import { useRecords } from "@latticexyz/stash/react";
import { stash } from "./mud/stash";
import { tables } from "./common";
import { useAccount } from "wagmi";
import { useCallback, useMemo } from "react";
import { removeAllowance } from "./removeAllowance";
import { useSessionClient } from "@latticexyz/entrykit/internal";
import { Hex } from "viem";

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
  const { data: sessionClient } = useSessionClient();
  const handleRemoveAllowance = useCallback(
    async (user: Hex, sponsor: Hex) => {
      if (!sessionClient) return;
      const result = await removeAllowance({
        user,
        sponsor,
        client: sessionClient,
      });
      console.log("result", result);
    },
    [sessionClient]
  );

  return (
    <div className="flex flex-col gap-4">
      <div>
        <div>Received</div>
        <div>
          {receivedAllowances.map(({ allowance, user, sponsor }) => (
            <li key={sponsor}>
              {sponsor}: {allowance.toString()}{" "}
              <button onClick={() => handleRemoveAllowance(user, sponsor)}>
                Remove
              </button>
            </li>
          ))}
        </div>
      </div>
      <div>
        <div>Provided</div>
        <div>
          {providedAllowances.map(({ allowance, user, sponsor }) => (
            <li key={user}>
              {user}: {allowance.toString()}{" "}
              <button onClick={() => handleRemoveAllowance(user, sponsor)}>
                Remove
              </button>
            </li>
          ))}
        </div>
      </div>
    </div>
  );
}
