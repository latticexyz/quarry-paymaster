import { chainConfig } from "viem/op-stack";
import { Chain } from "viem/chains";
import worlds from "contracts/worlds.json";

const sourceId = 17000; // Holesky
export const rhodolite = {
  id: 17420,
  name: "Rhodolite",
  nativeCurrency: {
    decimals: 18,
    name: "Ether",
    symbol: "ETH",
  },
  rpcUrls: {
    default: {
      http: ["https://rpc.rhodolitechain.com"],
    },
    bundler: {
      http: ["https://rpc.rhodolitechain.com"],
    },
    wiresaw: {
      http: ["https://rpc.rhodolitechain.com"],
    },
  },
  contracts: {
    ...chainConfig.contracts,
    l1StandardBridge: {
      [sourceId]: {
        address: "0x760eDdF161B8b1540ce6516471f348093e8e71ab",
        blockCreated: 2415540,
      },
    },
    quarryPaymaster: {
      address: worlds[17420]!.address,
      blockCreated: worlds[17420]!.blockNumber,
    },
    counter: {
      address: "0xbe4ab86c44aba5a9a26a346ee06c8f0a52dddb26",
      blockCreated: 327717,
    },
  },
} satisfies Chain;
