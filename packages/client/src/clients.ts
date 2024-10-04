import {
  createPublicClient,
  fallback,
  webSocket,
  http,
  createWalletClient,
  ClientConfig,
  PublicClient,
  Hex,
} from "viem";
import { createBurnerAccount } from "@latticexyz/common";
import { transactionQueue } from "@latticexyz/common/actions";
import { observer } from "@latticexyz/explorer/observer";
import { entryPoint06Address } from "viem/account-abstraction";
import { worldAddress as paymasterAddress } from "contracts/deploys/31337/latest.json";
import { toSimpleSmartAccount } from "permissionless/accounts";
import { createSmartAccountClient, SmartAccountClient } from "permissionless";
import { chain } from "./chain";

// for demo - 1st anvil key
const adminKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

// for demo - 2nd anvil key
const grantorKey = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";

// for demo - unfunded key
const userKey = "0xab824ae96b4d6bf50deddfc4ec7fe0ed54ce3e601277239c41f4630b98e5cef2";

const clientOptions = {
  chain,
  transport: fallback([webSocket(), http()]),
  pollingInterval: 10,
} as const satisfies ClientConfig;

export const publicClient: PublicClient = createPublicClient(clientOptions);

export const adminClient = createWalletClient({
  ...clientOptions,
  account: createBurnerAccount(adminKey),
})
  .extend(transactionQueue())
  .extend(observer());

export const grantorClient = createWalletClient({
  ...clientOptions,
  account: createBurnerAccount(grantorKey),
})
  .extend(transactionQueue())
  .extend(observer());

export const userClient = createWalletClient({
  ...clientOptions,
  account: createBurnerAccount(userKey),
})
  .extend(transactionQueue())
  .extend(observer());

const smartAccount = await toSimpleSmartAccount({
  client: publicClient,
  // entryPoint: { address: entryPoint07Address, version: "0.7" },
  entryPoint: { address: entryPoint06Address, version: "0.6" },
  // factoryAddress: "0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985",
  factoryAddress: "0x9406Cc6185a346906296840746125a0E44976454",
  owner: createBurnerAccount(userKey),
});

export const smartAccountClient: SmartAccountClient = createSmartAccountClient({
  chain,
  account: smartAccount,
  client: publicClient,
  bundlerTransport: http(chain.rpcUrls.erc4337.http[0]),
  paymaster: {
    async getPaymasterData() {
      // return { paymaster: paymasterAddress as Hex, paymasterData: "0x" };
      return { paymasterAndData: paymasterAddress as Hex };
    },
  },
});
