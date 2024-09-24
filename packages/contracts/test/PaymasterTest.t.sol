// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { EntryPoint } from "@account-abstraction/contracts/core/EntryPoint.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";

contract PaymasterTest is MudTest {
  EntryPoint entryPoint;
  IWorld paymaster;

  function setUp() public override {
    super.setUp();
    entryPoint = new EntryPoint();
    paymaster = IWorld(worldAddress);
  }

  function testWorldExists() public {
    uint256 codeSize;
    address addr = worldAddress;
    assembly {
      codeSize := extcodesize(addr)
    }
    assertTrue(codeSize > 0);
  }

  function testBalance() public {}
}
