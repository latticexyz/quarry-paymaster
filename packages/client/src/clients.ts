import { createPublicClient, http, createWalletClient, ClientConfig, PublicClient, Hex, HttpTransport } from "viem";
import { createBurnerAccount } from "@latticexyz/common";
import { transactionQueue } from "@latticexyz/common/actions";
import { observer } from "@latticexyz/explorer/observer";
import { entryPoint07Address, SmartAccount } from "viem/account-abstraction";
import { toSimpleSmartAccount } from "permissionless/accounts";
import { createSmartAccountClient, SmartAccountClient } from "permissionless";
import { chain } from "./chain";
import { paymaster } from "./contract";
import { wiresaw } from "./wiresaw";

// for demo - 1st and 2nd anvil key
const adminKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const grantorKey = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";

// for demo - unfunded key
const userKey = "0xab824ae96b4d6bf50deddfc4ec7fe0ed54ce3e601277239c41f4630b98e5cef2";

const clientOptions = {
  chain,
  transport: http(), // fallback([webSocket(), http()]),
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

const smartAccount: SmartAccount = await toSimpleSmartAccount({
  client: publicClient,
  entryPoint: { address: entryPoint07Address, version: "0.7" },
  factoryAddress: "0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985",
  owner: createBurnerAccount(userKey),
});

export const smartAccountClient: SmartAccountClient<HttpTransport, typeof chain, typeof smartAccount> =
  createSmartAccountClient({
    chain,
    account: smartAccount,
    client: publicClient,
    bundlerTransport: wiresaw(http(chain.rpcUrls.erc4337.http[0])),
    paymaster: {
      async getPaymasterData() {
        return { paymaster: paymaster.address, paymasterData: "0x" };
      },
    },
  });
