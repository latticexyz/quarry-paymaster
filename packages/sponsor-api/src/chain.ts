import { anvil } from "viem/chains";
import { Chain } from "viem";
import worlds from "contracts/worlds.json";
import env from "./env";
import { garnet } from "./garnet";

const anvilWithPaymaster = {
  ...anvil,
  contracts: {
    quarryPaymaster: {
      address: worlds[31337]!.address,
      blockCreated: worlds[31337]!.blockNumber,
    },
  },
} satisfies Chain;

const supportedChains = [anvilWithPaymaster, garnet];

const chain = supportedChains.find((c) => c.id === Number(env.CHAIN_ID))!;
if (!chain) {
  throw new Error("Unsupported chain: " + env.CHAIN_ID);
}

export { chain };
