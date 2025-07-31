import { useCallback, useState } from "react";
import { getAddress } from "viem";
import { grantAllowance } from "./grantAllowance";
import { useSessionClient } from "@latticexyz/entrykit/internal";

export function Sponsor() {
  const [user, setUser] = useState("");
  const [allowance, setAllowance] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const { data: sessionClient } = useSessionClient();

  const handleGrantAllowance = useCallback(async () => {
    if (!sessionClient) return;
    setError(null);
    setMessage(null);
    try {
      const result = await grantAllowance({
        receiver: getAddress(user),
        allowance: BigInt(allowance),
        client: sessionClient,
      });
      setMessage(result.message);
    } catch (error) {
      setError(error instanceof Error ? error.message : "Unknown error");
    }
  }, [user, allowance, sessionClient]);

  return (
    <div>
      <div>Sponsor</div>
      <div>
        <input
          className="border-2 border-gray-300 rounded-md p-2"
          type="text"
          value={user}
          onChange={(e) => setUser(e.target.value)}
        />
        <input
          className="border-2 border-gray-300 rounded-md p-2"
          type="number"
          value={allowance}
          onChange={(e) => setAllowance(e.target.value)}
        />
        <button disabled={!sessionClient} onClick={handleGrantAllowance}>
          Give
        </button>
        {error && <div className="text-red-500">{error}</div>}
        {message && <div>{message}</div>}
      </div>
    </div>
  );
}
