import { createPublicClient, http, ClientConfig, PublicClient, Hex, HttpTransport } from "viem";
import { createBurnerAccount } from "@latticexyz/common";
import { createBundlerClient, entryPoint07Address, SmartAccount } from "viem/account-abstraction";
import { toSimpleSmartAccount } from "permissionless/accounts";
import { createSmartAccountClient, SmartAccountClient } from "permissionless";
import { chain } from "./chain";
import { paymaster } from "./contract";
import env from "./env";

const clientOptions = {
  chain,
  transport: http(), // fallback([webSocket(), http()]),
  pollingInterval: 10,
} as const satisfies ClientConfig;

export const publicClient: PublicClient = createPublicClient(clientOptions);

export const bundlerClient = createBundlerClient({
  ...clientOptions,
  transport: http(chain.rpcUrls.erc4337.http[0]),
});

let smartAccount: SmartAccount;
async function getSmartAccount(): Promise<SmartAccount> {
  if (smartAccount) {
    return smartAccount;
  }

  smartAccount = await toSimpleSmartAccount({
    client: publicClient,
    entryPoint: { address: entryPoint07Address, version: "0.7" },
    factoryAddress: "0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985",
    owner: createBurnerAccount(env.ISSUER_PRIVATE_KEY as Hex),
  });

  return smartAccount;
}

let smartAccountClient: SmartAccountClient<HttpTransport, typeof chain, typeof smartAccount>;
export async function getSmartAccountClient(): Promise<
  SmartAccountClient<HttpTransport, typeof chain, typeof smartAccount>
> {
  if (smartAccountClient) {
    return smartAccountClient;
  }

  smartAccountClient = createSmartAccountClient({
    chain,
    account: await getSmartAccount(),
    client: publicClient,
    bundlerTransport: http(chain.rpcUrls.erc4337.http[0]),
    paymaster: {
      async getPaymasterData() {
        return { paymaster: paymaster.address, paymasterData: "0x" };
      },
    },
  });

  return smartAccountClient;
}
