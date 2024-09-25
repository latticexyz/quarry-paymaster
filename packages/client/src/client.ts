import {
  createPublicClient,
  fallback,
  webSocket,
  http,
  createWalletClient,
  Hex,
  ClientConfig,
  WalletClient,
  PublicClient,
} from "viem";
import { anvil } from "viem/chains";
import { createBurnerAccount } from "@latticexyz/common";
import { transactionQueue } from "@latticexyz/common/actions";

function getPrivateKey(): Hex {
  return (
    (new URL(window.location.href).searchParams.get("privateKey") as Hex) ??
    "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
  );
}

function getClient(): { public: PublicClient; wallet: WalletClient } {
  const clientOptions = {
    chain: anvil,
    transport: fallback([webSocket(), http()]),
    pollingInterval: 10,
  } as const satisfies ClientConfig;

  const publicClient = createPublicClient(clientOptions);

  const burnerAccount = createBurnerAccount(getPrivateKey());
  const walletClient = createWalletClient({
    ...clientOptions,
    account: burnerAccount,
  }).extend(transactionQueue());

  return { public: publicClient, wallet: walletClient };
}

export const client = getClient();
