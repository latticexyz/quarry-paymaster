// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { SystemConfig } from "../src/namespaces/root/codegen/tables/SystemConfig.sol";
import { PassConfig } from "../src/namespaces/root/codegen/tables/PassConfig.sol";
import { Allowance } from "../src/namespaces/root/codegen/tables/Allowance.sol";

contract FundIssuer is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address issuerAddress = vm.envAddress("ISSUER_ADDRESS");
    IWorld paymaster = IWorld(worldAddress);
    bytes32 passId = bytes32(uint256(1));

    // Check the World owner
    address owner = NamespaceOwner.get(ROOT_NAMESPACE_ID);
    console.log("Paymaster owner:", owner);

    // Check the pass owner
    address passOwner = PassConfig.getGrantor(passId);
    console.log("Pass owner:", passOwner);

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    // Set a grant allowance for the paymaster service to grant allowance to users
    paymaster.setGrantAllowance(issuerAddress, 1 ether);

    // Reset pass owner
    PassConfig.setGrantor(passId, address(0));

    // Register pass to issue to users
    paymaster.registerPass({
      passId: passId,
      claimAmount: 0.05 ether,
      claimInterval: 24 hours,
      validityPeriod: 30 days
    });

    // Transfer ownership of the pass to the service account
    PassConfig.setGrantor(passId, issuerAddress);

    // Grant a high allowance to the paymaster service to send user operations to issue passes and claim allowance
    Allowance.setAllowance(issuerAddress, 999999 ether);

    vm.stopBroadcast();
  }
}
