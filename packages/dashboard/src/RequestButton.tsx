import { useMutation } from "@tanstack/react-query";
import { requestAllowance } from "./requestAllowance";
import { useSessionClient } from "@latticexyz/entrykit/internal";
import { Hex } from "viem";
import { getChain } from "./common";
import { useAccount } from "wagmi";
import { twMerge } from "tailwind-merge";

export function RequestButton() {
  const { data: sessionClient } = useSessionClient();
  const account = useAccount();

  const request = useMutation({
    mutationKey: ["requestAllowance", sessionClient?.uid],
    async mutationFn({ user }: { user: Hex }) {
      return await requestAllowance({ chain: getChain(), userAddress: user });
    },
  });

  const disabled = !account.address;

  return (
    <>
      <form
        className="flex flex-col gap-2"
        onSubmit={(event) => {
          event.preventDefault();
          if (!account.address) throw new Error("Not connected.");
          request.mutate({ user: account.address });
        }}
      >
        <button
          type="submit"
          className={twMerge(
            "group",
            "bg-orange-500 hover:brightness-125 active:brightness-90 text-white font-medium cursor-pointer",
            "disabled:pointer-events-none disabled:opacity-40 disabled:grayscale",
            "aria-busy:pointer-events-none aria-busy:animate-pulse",
            "focus:outline-2 focus:outline-blue-400/60"
          )}
          disabled={disabled}
          aria-busy={request.isPending}
        >
          <span className="p-2 inline-grid *:col-start-1 *:row-start-1 overflow-clip">
            <span className="transition group-aria-busy:-translate-y-2 group-aria-busy:opacity-0">
              Request allowance
            </span>
            <span
              className="transition translate-y-4 group-aria-busy:translate-y-0 not-group-aria-busy:opacity-0"
              aria-hidden
            >
              ⋯
            </span>
          </span>
        </button>
      </form>
      <div className="text-red-500">
        {request.error ? request.error.message : null}
      </div>
    </>
  );
}
