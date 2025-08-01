// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { AllowanceSystem, MIN_ALLOWANCE, MAX_NUM_ALLOWANCES } from "../src/namespaces/root/systems/AllowanceSystem.sol";
import { Allowance, AllowanceData } from "../src/namespaces/root/codegen/tables/Allowance.sol";
import { AllowanceList, AllowanceListData } from "../src/namespaces/root/codegen/tables/AllowanceList.sol";
import { Balance } from "../src/namespaces/root/codegen/tables/Balance.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { SystemConfig } from "../src/namespaces/root/codegen/tables/SystemConfig.sol";
import { EntryPoint } from "@account-abstraction/contracts/core/EntryPoint.sol";

import { printAllowance } from "./utils/printAllowance.sol";

contract AllowanceTest is MudTest {
  EntryPoint entryPoint;
  IWorld paymaster;

  address user;
  address sponsor1;
  address sponsor2;
  address sponsor3;
  address admin;

  uint256 sponsorBalance = 10 ether;

  function setUp() public override {
    super.setUp();
    entryPoint = new EntryPoint();
    paymaster = IWorld(worldAddress);

    user = makeAddr("user");
    sponsor1 = makeAddr("sponsor1");
    sponsor2 = makeAddr("sponsor2");
    sponsor3 = makeAddr("sponsor3");
    admin = NamespaceOwner.get(ROOT_NAMESPACE_ID);

    // Set the entrypoint address
    vm.prank(admin);
    SystemConfig.setEntryPoint(address(entryPoint));

    // Give sponsors initial balances
    vm.deal(sponsor1, sponsorBalance);
    vm.prank(sponsor1);
    paymaster.depositTo{ value: sponsorBalance }(sponsor1);

    vm.deal(sponsor2, sponsorBalance);
    vm.prank(sponsor2);
    paymaster.depositTo{ value: sponsorBalance }(sponsor2);

    vm.deal(sponsor3, sponsorBalance);
    vm.prank(sponsor3);
    paymaster.depositTo{ value: sponsorBalance }(sponsor3);
  }

  function testWorldExists() public {
    uint256 codeSize;
    address addr = worldAddress;
    assembly {
      codeSize := extcodesize(addr)
    }
    assertTrue(codeSize > 0);
  }

  function testGrantAllowanceWithoutBalance() public {
    address sponsorWithoutBalance = makeAddr("sponsorWithoutBalance");
    uint256 allowanceAmount = 1 ether;

    // Try to grant allowance without having a balance
    vm.prank(sponsorWithoutBalance);
    vm.expectRevert(
      abi.encodeWithSignature("AllowanceSystem_InsufficientBalance(uint256,uint256)", 0, allowanceAmount)
    );
    paymaster.grantAllowance(user, allowanceAmount);
  }

  function testGrantAllowanceBalanceDecreasesAllowanceIncreases() public {
    uint256 allowanceAmount = 1 ether;
    uint256 initialSponsorBalance = Balance.get(sponsor1);
    uint256 initialUserAllowance = paymaster.getAllowance(user);

    // Grant allowance
    vm.prank(sponsor1);
    paymaster.grantAllowance(user, allowanceAmount);

    // Check sponsor's balance decreased
    assertEq(Balance.get(sponsor1), initialSponsorBalance - allowanceAmount);

    // Check user's allowance increased
    assertEq(paymaster.getAllowance(user), initialUserAllowance + allowanceAmount);

    // Check specific allowance from sponsor1 to user
    assertEq(Allowance.getAllowance(user, sponsor1), allowanceAmount);
  }

  function testGrantMultipleAllowancesOrdered() public {
    // Grant allowances in non-sorted order
    uint256 allowance2 = 2 ether;
    uint256 allowance1 = 1 ether;
    uint256 allowance3 = 3 ether;

    vm.prank(sponsor2);
    paymaster.grantAllowance(user, allowance2);

    vm.prank(sponsor1);
    paymaster.grantAllowance(user, allowance1);

    vm.prank(sponsor3);
    paymaster.grantAllowance(user, allowance3);

    // Check that the list is ordered from lowest to highest
    AllowanceListData memory list = AllowanceList.get(user);
    assertEq(list.length, 3);

    // First should be sponsor1 with 1 ether
    address currentSponsor = list.first;
    assertEq(currentSponsor, sponsor1);
    AllowanceData memory currentAllowance = Allowance.get(user, currentSponsor);
    assertEq(currentAllowance.allowance, allowance1);
    assertEq(currentAllowance.previous, address(0));

    // Next should be sponsor2 with 2 ether
    currentSponsor = currentAllowance.next;
    assertEq(currentSponsor, sponsor2);
    currentAllowance = Allowance.get(user, currentSponsor);
    assertEq(currentAllowance.allowance, allowance2);
    assertEq(currentAllowance.previous, sponsor1);

    // Last should be sponsor3 with 3 ether
    currentSponsor = currentAllowance.next;
    assertEq(currentSponsor, sponsor3);
    currentAllowance = Allowance.get(user, currentSponsor);
    assertEq(currentAllowance.allowance, allowance3);
    assertEq(currentAllowance.previous, sponsor2);
    assertEq(currentAllowance.next, address(0));
  }

  function testRemoveLowestAllowanceUpdatesRoot() public {
    // Grant three allowances
    vm.prank(sponsor1);
    paymaster.grantAllowance(user, 1 ether);

    vm.prank(sponsor2);
    paymaster.grantAllowance(user, 2 ether);

    vm.prank(sponsor3);
    paymaster.grantAllowance(user, 3 ether);

    // Verify initial root
    assertEq(AllowanceList.getFirst(user), sponsor1);

    // Remove the lowest allowance (sponsor1)
    vm.prank(sponsor1);
    paymaster.removeAllowance(user, sponsor1);

    // Check that root is updated to sponsor2
    assertEq(AllowanceList.getFirst(user), sponsor2);
    assertEq(AllowanceList.getLength(user), 2);

    // Verify sponsor1's balance was restored
    assertEq(Balance.get(sponsor1), sponsorBalance);
  }

  function testRemoveMiddleAllowanceUpdatesPointers() public {
    // Grant three allowances
    vm.prank(sponsor1);
    paymaster.grantAllowance(user, 1 ether);

    vm.prank(sponsor2);
    paymaster.grantAllowance(user, 2 ether);

    vm.prank(sponsor3);
    paymaster.grantAllowance(user, 3 ether);

    // Remove the middle allowance (sponsor2)
    vm.prank(sponsor2);
    paymaster.removeAllowance(user, sponsor2);

    // Check list integrity
    assertEq(AllowanceList.getFirst(user), sponsor1);
    assertEq(AllowanceList.getLength(user), 2);

    // Check that sponsor1 now points to sponsor3
    AllowanceData memory sponsor1Allowance = Allowance.get(user, sponsor1);
    assertEq(sponsor1Allowance.next, sponsor3);

    // Check that sponsor3 still has no next
    AllowanceData memory sponsor3Allowance = Allowance.get(user, sponsor3);
    assertEq(sponsor3Allowance.next, address(0));

    // Verify sponsor2's balance was restored
    assertEq(Balance.get(sponsor2), sponsorBalance);
  }

  function testRemoveAllowanceRestoresBalance() public {
    uint256 allowanceAmount = 2 ether;

    // Grant allowance
    vm.prank(sponsor1);
    paymaster.grantAllowance(user, allowanceAmount);

    // Verify balance decreased
    assertEq(Balance.get(sponsor1), sponsorBalance - allowanceAmount);

    // Remove allowance
    vm.prank(sponsor1);
    paymaster.removeAllowance(user, sponsor1);

    // Verify balance restored
    assertEq(Balance.get(sponsor1), sponsorBalance);
    assertEq(paymaster.getAllowance(user), 0);
  }

  function testOnlyUserOrSponsorCanRemoveAllowance() public {
    // Grant allowance
    vm.prank(sponsor1);
    paymaster.grantAllowance(user, 1 ether);

    // Try to remove as unauthorized address
    address unauthorized = makeAddr("unauthorized");
    vm.prank(unauthorized);
    vm.expectRevert(
      abi.encodeWithSignature("AllowanceSystem_NotAuthorized(address,address,address)", unauthorized, sponsor1, user)
    );
    paymaster.removeAllowance(user, sponsor1);

    // Remove as user should work
    vm.prank(user);
    paymaster.removeAllowance(user, sponsor1);
    assertEq(paymaster.getAllowance(user), 0);

    // Grant again
    vm.prank(sponsor1);
    paymaster.grantAllowance(user, 1 ether);

    // Remove as sponsor should work
    vm.prank(sponsor1);
    paymaster.removeAllowance(user, sponsor1);
    assertEq(paymaster.getAllowance(user), 0);
  }

  function testAllowanceBelowMinimum() public {
    uint256 tooSmallAllowance = MIN_ALLOWANCE - 1;

    vm.prank(sponsor1);
    vm.expectRevert(
      abi.encodeWithSignature(
        "AllowanceSystem_AllowanceBelowMinimum(uint256,uint256)",
        tooSmallAllowance,
        MIN_ALLOWANCE
      )
    );
    paymaster.grantAllowance(user, tooSmallAllowance);
  }

  function testAllowancesLimitReached() public {
    // Grant maximum number of allowances
    for (uint256 i = 0; i < MAX_NUM_ALLOWANCES; i++) {
      address sponsor = makeAddr(string(abi.encodePacked("sponsor", i)));
      vm.deal(sponsor, 1 ether);
      vm.prank(sponsor);
      paymaster.depositTo{ value: 1 ether }(sponsor);

      vm.prank(sponsor);
      paymaster.grantAllowance(user, MIN_ALLOWANCE + i * 1000); // Different amounts to ensure ordering
    }

    // Try to grant one more
    address extraSponsor = makeAddr("extraSponsor");
    vm.deal(extraSponsor, 1 ether);
    vm.prank(extraSponsor);
    paymaster.depositTo{ value: 1 ether }(extraSponsor);

    vm.prank(extraSponsor);
    vm.expectRevert(
      abi.encodeWithSignature(
        "AllowanceSystem_AllowancesLimitReached(uint256,uint256)",
        MAX_NUM_ALLOWANCES,
        MAX_NUM_ALLOWANCES
      )
    );
    paymaster.grantAllowance(user, MIN_ALLOWANCE);
  }

  function testGrantAdditionalAllowanceFromSameSponsor() public {
    uint256 firstAllowance = 1 ether;
    uint256 additionalAllowance = 0.5 ether;

    // Grant first allowance
    vm.prank(sponsor1);
    paymaster.grantAllowance(user, firstAllowance);

    // Grant additional allowance from same sponsor
    vm.prank(sponsor1);
    paymaster.grantAllowance(user, additionalAllowance);

    // Check that allowances were combined
    assertEq(Allowance.getAllowance(user, sponsor1), firstAllowance + additionalAllowance);
    assertEq(paymaster.getAllowance(user), firstAllowance + additionalAllowance);
    assertEq(AllowanceList.getLength(user), 1); // Still only one entry in the list
  }
}
