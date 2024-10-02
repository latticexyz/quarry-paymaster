// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { SystemConfig } from "../src/namespaces/root/codegen/tables/SystemConfig.sol";

contract FundPaymaster is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    IEntryPoint entryPoint06 = IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    entryPoint.depositTo{ value: 0.1 ether }(worldAddress);

    vm.stopBroadcast();
  }
}
