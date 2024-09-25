// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { EntryPoint, IEntryPoint } from "@account-abstraction/contracts/core/EntryPoint.sol";
import { PackedUserOperation } from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { SimpleAccountFactory, SimpleAccount } from "@account-abstraction/contracts/samples/SimpleAccountFactory.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { PaymasterSystem } from "../src/namespaces/root/systems/PaymasterSystem.sol";
import { Allowance } from "../src/namespaces/root/codegen/tables/Allowance.sol";
import { Grantor } from "../src/namespaces/root/codegen/tables/Grantor.sol";
import { SystemConfig } from "../src/namespaces/root/codegen/tables/SystemConfig.sol";
import { TestCounter } from "./utils/TestCounter.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";

contract PassTest is MudTest {
  IWorld paymaster;
  address admin;
  address grantor;
  address user;
  uint256 grantAllowance = 10 ether;

  function setUp() public override {
    super.setUp();
    paymaster = IWorld(worldAddress);
    admin = NamespaceOwner.get(ROOT_NAMESPACE_ID);
    grantor = payable(makeAddr("grantor"));
    user = makeAddr("user");

    vm.prank(admin);
    paymaster.setGrantAllowance(grantor, grantAllowance);
  }
}
