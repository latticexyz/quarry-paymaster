import { useCallback, useState } from "react";
import { Address, getAddress, isAddress, parseEther } from "viem";
import { grantAllowance } from "./grantAllowance";
import { SessionClient, useSessionClient } from "@latticexyz/entrykit/internal";
import { useMutation } from "@tanstack/react-query";
import { twMerge } from "tailwind-merge";

export function Sponsor() {
  const { data: sessionClient } = useSessionClient();

  const grant = useMutation({
    mutationKey: ["grantAllowance", sessionClient?.uid],
    async mutationFn({ formData }: { formData: FormData }) {
      if (!sessionClient) throw new Error("Not connected.");

      // TODO: parse form data with arktype or effect schema?

      const receiver = formData.get("receiver");
      if (typeof receiver !== "string" || !isAddress(receiver)) {
        throw new Error("Invalid receiver address.");
      }

      const allowance = parseEther(formData.get("allowance") as string);
      if (allowance <= 0) throw new Error("Invalid allowance.");

      return await grantAllowance({
        receiver: getAddress(receiver),
        allowance: BigInt(allowance),
        client: sessionClient,
      });
    },
  });

  return (
    <form
      className="flex flex-col gap-2"
      onSubmit={(event) => {
        event.preventDefault();
        grant.mutate({ formData: new FormData(event.currentTarget) });
      }}
    >
      <label
        className={twMerge(
          "inline-flex border border-neutral-600 text-sm",
          "focus-within:outline-2 focus-within:outline-blue-400/60 focus-within:text-white"
        )}
      >
        <input
          name="receiver"
          required
          className="w-full p-2 outline-none"
          placeholder="Receiver (Ethereum address)"
        />
      </label>
      <div className="flex flex-col">
        <div className="flex gap-1">
          {["0.005", "0.01", "0.05", "0.1"].map((amount) => (
            <button
              key={amount}
              type="button"
              className="grow p-1.5 text-xs leading-none bg-neutral-700 hover:brightness-125 active:brightness-90 text-white cursor-pointer focus:outline-2 focus:outline-blue-400/60"
              onClick={(event) => {
                const input = event.currentTarget.form?.allowance;
                if (!input) throw new Error("Could not find allowance input.");

                input.value = amount;
                input.focus();
              }}
            >
              {amount}&nbsp;ETH
            </button>
          ))}
        </div>
        <label
          className={twMerge(
            "inline-flex border border-neutral-600 text-sm",
            "focus-within:outline-2 focus-within:outline-blue-400/60 focus-within:text-white"
          )}
        >
          <input
            name="allowance"
            required
            className="w-full p-2 outline-none"
            placeholder="Allowance amount"
          />
          <div className="m-1 p-2 text-xs leading-none bg-neutral-700 text-white inline-flex items-center">
            ETH
          </div>
        </label>
      </div>
      <button
        type="submit"
        className={twMerge(
          "group",
          "bg-orange-500 hover:brightness-125 active:brightness-90 text-white font-medium cursor-pointer",
          "disabled:pointer-events-none disabled:opacity-40 disabled:grayscale",
          "aria-busy:pointer-events-none aria-busy:animate-pulse",
          "focus:outline-2 focus:outline-blue-400/60"
        )}
        disabled={!sessionClient}
        aria-busy={grant.isPending}
      >
        <span className="p-2 inline-grid *:col-start-1 *:row-start-1 overflow-clip">
          <span className="transition group-aria-busy:-translate-y-2 group-aria-busy:opacity-0">
            Grant allowance
          </span>
          <span
            className="transition translate-y-4 group-aria-busy:translate-y-0 not-group-aria-busy:opacity-0"
            aria-hidden
          >
            ⋯
          </span>
        </span>
      </button>
      {grant.error ? (
        <div className="text-red-500">{grant.error.message}</div>
      ) : null}
      {grant.data ? <div>{grant.data.message}</div> : null}
    </form>
  );
}
