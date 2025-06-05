// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { SystemConfig } from "../src/namespaces/root/codegen/tables/SystemConfig.sol";

contract PostDeployKms is Script {
  function run(address worldAddress, address deployer) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    IEntryPoint entryPoint07 = IEntryPoint(0x0000000071727De22E5E9d8BAf0edAc6f37da032);

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployer);

    SystemConfig.set(address(entryPoint07));

    vm.stopBroadcast();
  }
}
