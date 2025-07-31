// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console2 as console } from "forge-std/console2.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { Balance } from "../src/namespaces/root/codegen/tables/Balance.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { SystemConfig } from "../src/namespaces/root/codegen/tables/SystemConfig.sol";

contract FundSponsor is Script {
  function run(address worldAddress) external {
    StoreSwitch.setStoreAddress(worldAddress);

    address sponsorAddress = vm.envAddress("SPONSOR_ADDRESS");
    IWorld paymaster = IWorld(worldAddress);

    uint256 targetBalance = 1 ether;
    uint256 balance = Balance.get(sponsorAddress);
    console.log("Current sponsor balance: %s", balance);

    if (balance < targetBalance) {
      uint256 amount = targetBalance - balance;
      console.log("Funding sponsor with %s", amount);
      uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
      vm.startBroadcast(deployerPrivateKey);
      paymaster.depositTo{ value: amount }(sponsorAddress);
      vm.stopBroadcast();
    }
  }
}
