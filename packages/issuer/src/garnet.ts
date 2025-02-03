import { Chain } from "viem/chains";
import worlds from "contracts/worlds.json";
import { garnet as garnetChain } from "@latticexyz/common/chains";

export const garnet = {
  ...garnetChain,
  rpcUrls: {
    ...garnetChain.rpcUrls,
    bundler: {
      http: ["https://rpc.garnetchain.com"],
    },
  },
  contracts: {
    ...garnetChain.contracts,
    quarryPaymaster: {
      address: worlds[17069]!.address,
      blockCreated: worlds[17069]!.blockNumber,
    },
  },
} satisfies Chain;
