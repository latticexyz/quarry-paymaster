import { anvil } from "viem/chains";
import { rhodolite } from "./rhodolite";
import { Chain } from "viem";
import paymasters from "contracts/worlds.json";

const anvilWithPaymaster = {
  ...anvil,
  rpcUrls: {
    ...anvil.rpcUrls,
    erc4337: {
      http: ["http://127.0.0.1:4337"],
    },
  },
  contracts: {
    quarryPaymaster: {
      address: paymasters[31337]!.address,
      blockCreated: paymasters[31337]!.blockNumber,
    },
  },
} satisfies Chain;

const params = new URLSearchParams(window.location.search);
const chainId = Number(params.get("chainId") || params.get("chainid") || import.meta.env.VITE_CHAIN_ID || 31337);

const supportedChains = [anvilWithPaymaster, rhodolite];

const chain = supportedChains.find((c) => c.id === chainId)!;
if (!chain) {
  throw new Error("Unsupported chain: " + chainId);
}

export { chain };
