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
    StoreSwitch.setStoreAddress(worldAddress);
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    IEntryPoint entryPoint = IEntryPoint(0x0000000071727De22E5E9d8BAf0edAc6f37da032);
    uint256 targetBalance = 10 ether;
    uint256 balance = entryPoint.balanceOf(worldAddress);
    console.log("Current paymaster balance: %s", balance);
    if (balance < targetBalance) {
      uint256 amount = targetBalance - balance;
      console.log("Funding paymaster with %s", amount);
      vm.startBroadcast(deployerPrivateKey);
      entryPoint.depositTo{ value: amount }(worldAddress);
      vm.stopBroadcast();
    }
  }
}
