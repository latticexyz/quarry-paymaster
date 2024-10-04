import { chainConfig } from "viem/op-stack";
import { Chain } from "viem/chains";
import { Hex } from "viem";
import paymaster from "contracts/deploys/17420/latest.json";

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
    // TODO: put behind peroxide/proxyd
    erc4337: {
      http: ["http://79.127.239.88:54337"],
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
      address: paymaster.worldAddress as Hex,
      blockCreated: paymaster.blockNumber,
    },
    counter: {
      address: "0xbe4ab86c44aba5a9a26a346ee06c8f0a52dddb26",
      blockCreated: 327717,
    },
  },
} satisfies Chain;
