import { Chain, http, webSocket } from "viem";
import { anvil as anvilConfig } from "viem/chains";
import { createWagmiConfig } from "@latticexyz/entrykit/internal";
import {
  garnet,
  pyrope,
  redstone as redstoneConfig,
} from "@latticexyz/common/chains";
import { chainId } from "./common";
import worlds from "contracts/worlds.json";

const redstone = {
  ...redstoneConfig,
  rpcUrls: {
    ...redstoneConfig.rpcUrls,
    bundler: {
      http: ["https://rpc.redstonechain.com"],
    },
    quarrySponsor: {
      http: ["https://sponsor.mud.redstonechain.com/rpc"],
    },
  },
  contracts: {
    ...redstoneConfig.contracts,
    quarryPaymaster: {
      address: worlds[690]!.address,
      blockCreated: worlds[690]!.blockNumber,
    },
  },
};

const anvil = {
  ...anvilConfig,
  contracts: {
    ...anvilConfig.contracts,
    paymaster: {
      address: "0xf03E61E7421c43D9068Ca562882E98d1be0a6b6e",
    },
  },
  blockExplorers: {
    default: {} as never,
    worldsExplorer: {
      name: "MUD Worlds Explorer",
      url: "http://localhost:13690/anvil/worlds",
    },
  },
  rpcUrls: {
    ...anvilConfig.rpcUrls,
    quarrySponsor: {
      http: ["http://localhost:3003/rpc"],
    },
  },
};

export const chains = [
  redstone,
  garnet,
  pyrope,
  anvil,
] as const satisfies Chain[];

export const transports = {
  [anvil.id]: webSocket(),
  [garnet.id]: http(),
  [pyrope.id]: http(),
  [redstone.id]: http(),
} as const;

export const wagmiConfig = createWagmiConfig({
  chainId,
  // TODO: swap this with another default project ID or leave empty
  walletConnectProjectId: "3f1000f6d9e0139778ab719fddba894a",
  appName: document.title,
  chains,
  transports,
  pollingInterval: {
    [anvil.id]: 2000,
    [garnet.id]: 2000,
    [pyrope.id]: 2000,
    [redstone.id]: 2000,
  },
});
