import { anvil as anvilConfig } from "viem/chains";
import { Chain } from "viem";
import worlds from "contracts/worlds.json";
import env from "./env";
import { garnet, pyrope, redstone as redstoneConfig } from "@latticexyz/common/chains";

const anvilWithPaymaster = {
  ...anvilConfig,
  contracts: {
    quarryPaymaster: {
      address: worlds[31337]!.address,
      blockCreated: worlds[31337]!.blockNumber,
    },
  },
} satisfies Chain;

const redstone = {
  ...redstoneConfig,
  rpcUrls: {
    ...redstoneConfig.rpcUrls,
    bundler: {
      http: ["https://rpc.redstonechain.com"],
    },
  },
  contracts: {
    quarryPaymaster: {
      address: worlds[690]!.address,
      blockCreated: worlds[690]!.blockNumber,
    },
  },
} satisfies Chain;

const supportedChains = [anvilWithPaymaster, garnet, pyrope, redstone];

const chain = supportedChains.find((c) => c.id === Number(env.CHAIN_ID))!;
if (!chain) {
  throw new Error("Unsupported chain: " + env.CHAIN_ID);
}

export { chain };
