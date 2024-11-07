import { anvil } from "viem/chains";
import { rhodolite } from "./rhodolite";
import { Chain } from "viem";
import worlds from "contracts/worlds.json";
import env from "./env";

const anvilWithPaymaster = {
  ...anvil,
  rpcUrls: {
    ...anvil.rpcUrls,
    bundler: {
      http: ["http://127.0.0.1:4337"],
    },
  },
  contracts: {
    quarryPaymaster: {
      address: worlds[31337]!.address,
      blockCreated: worlds[31337]!.blockNumber,
    },
  },
} satisfies Chain;

const supportedChains = [anvilWithPaymaster, rhodolite];

const chain = supportedChains.find((c) => c.id === Number(env.CHAIN_ID))!;
if (!chain) {
  throw new Error("Unsupported chain: " + env.CHAIN_ID);
}

export { chain };
