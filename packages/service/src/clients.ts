import { createPublicClient, http, ClientConfig, PublicClient, Hex, HttpTransport } from "viem";
import { createBurnerAccount } from "@latticexyz/common";
import { entryPoint06Address, SmartAccount } from "viem/account-abstraction";
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

let smartAccount: SmartAccount;
async function getSmartAccount(): Promise<SmartAccount> {
  if (smartAccount) {
    return smartAccount;
  }

  smartAccount = await toSimpleSmartAccount({
    client: publicClient,
    // entryPoint: { address: entryPoint07Address, version: "0.7" },
    entryPoint: { address: entryPoint06Address, version: "0.6" },
    // factoryAddress: "0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985",
    factoryAddress: "0x9406Cc6185a346906296840746125a0E44976454",
    owner: createBurnerAccount(env.SIGNER_PRIVATE_KEY as Hex),
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
        // return { paymaster: paymasterAddress as Hex, paymasterData: "0x" }; // 0.7
        return { paymasterAndData: paymaster.address as Hex };
      },
    },
  });

  return smartAccountClient;
}
