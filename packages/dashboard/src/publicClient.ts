import {
  createPublicClient,
  fallback,
  http,
  PublicClient,
  webSocket,
} from "viem";
import { getChain } from "./common";

export const publicClient: PublicClient = createPublicClient({
  chain: getChain(),
  transport: fallback([webSocket(), http()]),
});
