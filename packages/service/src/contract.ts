import WorldABI from "contracts/out/IWorld.sol/IWorld.abi.json";
import { chain } from "./chain";

export const paymaster = { abi: WorldABI, address: chain.contracts.quarryPaymaster.address, chain };
