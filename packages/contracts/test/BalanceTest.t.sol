// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { EntryPoint, IEntryPoint } from "@account-abstraction/contracts/core/EntryPoint.sol";
import { SimpleAccountFactory, SimpleAccount } from "@account-abstraction/contracts/samples/SimpleAccountFactory.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { Balance } from "../src/namespaces/root/codegen/tables/Balance.sol";
import { SystemConfig } from "../src/namespaces/root/codegen/tables/SystemConfig.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";

contract BalanceTest is MudTest {
  EntryPoint entryPoint;
  SimpleAccountFactory accountFactory;
  IWorld paymaster;

  address payable beneficiary;
  address user;
  uint256 userKey;
  SimpleAccount account;

  function setUp() public override {
    super.setUp();
    entryPoint = new EntryPoint();
    accountFactory = new SimpleAccountFactory(entryPoint);
    paymaster = IWorld(worldAddress);

    beneficiary = payable(makeAddr("beneficiary"));
    (user, userKey) = makeAddrAndKey("user");
    account = accountFactory.createAccount(user, 0);

    address admin = NamespaceOwner.get(ROOT_NAMESPACE_ID);
    vm.prank(admin);
    SystemConfig.setEntryPoint(address(entryPoint));
  }

  function testWorldExists() public {
    uint256 codeSize;
    address addr = worldAddress;
    assembly {
      codeSize := extcodesize(addr)
    }
    assertTrue(codeSize > 0);
  }

  function testDeposit() public {
    uint256 depositAmount1 = 0.03 ether;
    uint256 depositAmount2 = 0.02 ether;
    vm.deal(user, depositAmount1 + depositAmount2);

    // First deposit
    vm.prank(user);
    paymaster.depositTo{ value: depositAmount1 }(user);
    assertEq(Balance.get(user), depositAmount1);

    // Second deposit
    vm.prank(user);
    paymaster.depositTo{ value: depositAmount2 }(user);
    assertEq(Balance.get(user), depositAmount1 + depositAmount2);
  }

  function testDepositFromDifferentAccount() public {
    address depositor = makeAddr("depositor");
    uint256 depositAmount = 0.05 ether;
    vm.deal(depositor, depositAmount);

    vm.prank(depositor);
    paymaster.depositTo{ value: depositAmount }(user);

    assertEq(Balance.get(user), depositAmount);
    assertEq(depositor.balance, 0);
  }

  function testWithdraw() public {
    // First deposit some funds
    uint256 depositAmount = 0.05 ether;
    vm.deal(user, depositAmount);
    vm.prank(user);
    paymaster.depositTo{ value: depositAmount }(user);

    // First withdrawal
    uint256 withdrawAmount1 = 0.02 ether;
    vm.prank(user);
    paymaster.withdrawTo(payable(user), withdrawAmount1);
    assertEq(Balance.get(user), depositAmount - withdrawAmount1);
    assertEq(user.balance, withdrawAmount1);

    // Second withdrawal
    uint256 withdrawAmount2 = 0.01 ether;
    vm.prank(user);
    paymaster.withdrawTo(payable(user), withdrawAmount2);
    assertEq(Balance.get(user), depositAmount - withdrawAmount1 - withdrawAmount2);
    assertEq(user.balance, withdrawAmount1 + withdrawAmount2);
  }

  function testWithdrawInsufficientBalance() public {
    // First deposit some funds
    uint256 depositAmount = 0.05 ether;
    vm.deal(user, depositAmount);
    vm.prank(user);
    paymaster.depositTo{ value: depositAmount }(user);

    // Try to withdraw more than balance
    uint256 withdrawAmount = 0.1 ether;
    vm.prank(user);
    vm.expectRevert(
      abi.encodeWithSignature(
        "BalanceSystem_InsufficientBalance(address,uint256,uint256)",
        user,
        withdrawAmount,
        depositAmount
      )
    );
    paymaster.withdrawTo(payable(user), withdrawAmount);
  }

  function testWithdrawToDifferentAddress() public {
    // First deposit some funds
    uint256 depositAmount = 0.05 ether;
    vm.deal(user, depositAmount);
    vm.prank(user);
    paymaster.depositTo{ value: depositAmount }(user);

    // Withdraw to a different address
    address recipient = makeAddr("recipient");
    uint256 withdrawAmount = 0.03 ether;
    vm.prank(user);
    paymaster.withdrawTo(payable(recipient), withdrawAmount);

    uint256 remainingBalance = Balance.get(user);
    assertEq(remainingBalance, depositAmount - withdrawAmount);
    assertEq(recipient.balance, withdrawAmount);
  }
}
