import { Hex } from "viem";
import WorldABI from "contracts/out/IWorld.sol/IWorld.abi.json";
import worldDeployment from "contracts/deploys/31337/latest.json";
import { anvil } from "viem/chains";

export const paymaster = { abi: WorldABI, address: worldDeployment.worldAddress as Hex, chain: anvil };
