// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { EntryPoint, IEntryPoint } from "@account-abstraction/contracts/core/EntryPoint.sol";
import { SimpleAccountFactory, SimpleAccount } from "@account-abstraction/contracts/samples/SimpleAccountFactory.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { PassSystem } from "../src/namespaces/root/systems/PassSystem.sol";
import { Allowance } from "../src/namespaces/root/codegen/tables/Allowance.sol";
import { Grantor } from "../src/namespaces/root/codegen/tables/Grantor.sol";
import { SystemConfig } from "../src/namespaces/root/codegen/tables/SystemConfig.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";

contract PassTest is MudTest {
  IWorld paymaster;
  address admin;
  address grantor;
  address user;
  uint256 grantAllowance = 3 ether;

  bytes32 passId = "test";
  uint256 claimAmount = 1 ether;
  uint256 claimInterval = 1 days;
  uint256 validityPeriod = 7 days;

  function setUp() public override {
    super.setUp();
    paymaster = IWorld(worldAddress);
    admin = NamespaceOwner.get(ROOT_NAMESPACE_ID);
    grantor = payable(makeAddr("grantor"));
    user = makeAddr("user");

    vm.prank(admin);
    paymaster.setGrantAllowance(grantor, grantAllowance);

    vm.prank(grantor);
    paymaster.registerPass({
      passId: passId,
      claimAmount: claimAmount,
      claimInterval: claimInterval,
      validityPeriod: validityPeriod
    });
  }

  function testRegisterPass_Unauthorized() public {
    address unauthorizedUser = makeAddr("unauthorizedUser");
    vm.prank(unauthorizedUser);
    vm.expectRevert(
      abi.encodeWithSelector(PassSystem.PassSystem_Unauthorized.selector, passId, unauthorizedUser, grantor)
    );

    // Attempt to register the same pass from a different user
    paymaster.registerPass({
      passId: passId,
      claimAmount: claimAmount,
      claimInterval: claimInterval,
      validityPeriod: validityPeriod
    });
  }

  function testClaimPass() public {
    // Issue the pass to the user
    vm.prank(grantor);
    paymaster.issuePass({ passId: passId, user: user });

    // Claim the pass
    paymaster.claimFor({ user: user, passId: passId });

    assertEq(Allowance.get(user), claimAmount);
    assertEq(Grantor.getAllowance(grantor), grantAllowance - claimAmount);
  }

  function testClaimPass_PassExpired() public {
    // Issue the pass to the user
    vm.prank(grantor);
    paymaster.issuePass({ passId: passId, user: user });

    // Fast forward time to after the validity period
    vm.warp(block.timestamp + validityPeriod + 1);

    // Attempt to claim the pass, expecting a revert due to pass expiration
    vm.expectRevert(
      abi.encodeWithSelector(
        PassSystem.PassSystem_PassExpired.selector,
        passId,
        validityPeriod,
        user,
        block.timestamp - validityPeriod - 1
      )
    );
    paymaster.claimFor({ user: user, passId: passId });
  }

  function testClaimPass_PendingCooldown() public {
    // Issue the pass to the user
    vm.prank(grantor);
    paymaster.issuePass({ passId: passId, user: user });

    // Claim the pass for the first time
    paymaster.claimFor({ user: user, passId: passId });
    uint256 firstClaim = block.timestamp;

    // Fast forward time right before the end of the cooldown period
    vm.warp(block.timestamp + claimInterval - 1);

    // Attempt to claim the pass again before the cooldown period has passed
    vm.expectRevert(
      abi.encodeWithSelector(PassSystem.PassSystem_PendingCooldown.selector, passId, claimInterval, user, firstClaim)
    );
    paymaster.claimFor({ user: user, passId: passId });

    // Fast forward time to after the cooldown period
    vm.warp(block.timestamp + claimInterval);

    // Claim the pass again after the cooldown period has passed
    paymaster.claimFor({ user: user, passId: passId });

    // Verify the allowance has been updated correctly
    assertEq(Allowance.get(user), 2 * claimAmount);
    assertEq(Grantor.getAllowance(grantor), grantAllowance - 2 * claimAmount);
  }

  function testClaimPass_InsufficientGrantorAllowance() public {
    // Issue the pass to the user
    vm.prank(grantor);
    paymaster.issuePass({ passId: passId, user: user });

    // Set the grantor's allowance to be less than the claim amount
    vm.prank(admin);
    paymaster.setGrantAllowance(grantor, claimAmount - 1);

    // Attempt to claim the pass, expecting a revert due to insufficient grantor allowance
    vm.expectRevert(
      abi.encodeWithSelector(
        PassSystem.PassSystem_InsufficientGrantorAllowance.selector,
        passId,
        grantor,
        claimAmount - 1,
        claimAmount
      )
    );
    paymaster.claimFor({ user: user, passId: passId });
  }
}
