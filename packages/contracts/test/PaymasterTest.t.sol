// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { EntryPoint, IEntryPoint } from "@account-abstraction/contracts/core/EntryPoint.sol";
import { PackedUserOperation } from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { SimpleAccountFactory, SimpleAccount } from "@account-abstraction/contracts/samples/SimpleAccountFactory.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { PaymasterSystem } from "../src/namespaces/root/systems/PaymasterSystem.sol";
import { Allowance } from "../src/namespaces/root/codegen/tables/Allowance.sol";
import { AllowanceLib } from "../src/namespaces/root/systems/AllowanceSystem.sol";
import { Balance } from "../src/namespaces/root/codegen/tables/Balance.sol";
import { SystemConfig } from "../src/namespaces/root/codegen/tables/SystemConfig.sol";
import { TestCounter } from "./utils/TestCounter.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";

contract PaymasterTest is MudTest {
  EntryPoint entryPoint;
  SimpleAccountFactory accountFactory;
  IWorld paymaster;
  TestCounter counter;

  address payable beneficiary;
  address user;
  uint256 userKey;
  address admin;
  address grantor;
  SimpleAccount account;

  uint256 sponsorBalance = 10 ether;

  function setUp() public override {
    super.setUp();
    entryPoint = new EntryPoint();
    accountFactory = new SimpleAccountFactory(entryPoint);
    paymaster = IWorld(worldAddress);
    counter = new TestCounter();

    beneficiary = payable(makeAddr("beneficiary"));
    (user, userKey) = makeAddrAndKey("user");
    admin = NamespaceOwner.get(ROOT_NAMESPACE_ID);
    grantor = payable(makeAddr("grantor"));
    account = accountFactory.createAccount(user, 0);

    vm.prank(admin);
    SystemConfig.setEntryPoint(address(entryPoint));

    vm.deal(grantor, sponsorBalance);
    vm.prank(grantor);
    paymaster.depositTo{ value: sponsorBalance }(grantor);
  }

  function testWorldExists() public {
    uint256 codeSize;
    address addr = worldAddress;
    assembly {
      codeSize := extcodesize(addr)
    }
    assertTrue(codeSize > 0);
  }

  // sanity check for everything works without paymaster
  function testCall() external {
    vm.deal(address(account), 1e18);
    PackedUserOperation memory op = fillUserOp(
      account,
      userKey,
      address(counter),
      0,
      abi.encodeWithSelector(TestCounter.count.selector)
    );
    op.signature = signUserOp(op, userKey);
    submitUserOp(op);
  }

  function testCallWithPaymaster_InsufficientBalance() external {
    vm.deal(address(account), 1e18);
    PackedUserOperation memory op = fillUserOp(
      account,
      userKey,
      address(counter),
      0,
      abi.encodeWithSelector(TestCounter.count.selector)
    );

    op.paymasterAndData = abi.encodePacked(address(paymaster), uint128(100000), uint128(100000));
    op.signature = signUserOp(op, userKey);

    expectUserOpRevert(
      abi.encodeWithSelector(
        PaymasterSystem.PaymasterSystem_InsufficientFunds.selector,
        address(account),
        uint256(380000000000000),
        uint256(0),
        uint256(0)
      )
    );
    submitUserOp(op);
  }

  function testCallWithPaymaster() external {
    vm.deal(address(account), 1e18);
    PackedUserOperation memory op = fillUserOp(
      account,
      userKey,
      address(counter),
      0,
      abi.encodeWithSelector(TestCounter.count.selector)
    );

    op.paymasterAndData = abi.encodePacked(address(paymaster), uint128(100000), uint128(100000));
    op.signature = signUserOp(op, userKey);

    // Grant sufficient computation units for the account
    uint256 requiredAllowance = 380000000000000;
    vm.prank(grantor);
    paymaster.grantAllowance(address(account), requiredAllowance);
    assertEq(Balance.getBalance(grantor), sponsorBalance - requiredAllowance);
    assertEq(AllowanceLib.getAvailableAllowance(address(account)), requiredAllowance);

    // Expect the user op to succeed now and the balance to be taken from the user account
    assertEq(beneficiary.balance, 0);
    submitUserOp(op);
    uint256 feePaidByPaymaster = sponsorBalance - entryPoint.balanceOf(address(paymaster));
    uint256 feePaidByUser = requiredAllowance - AllowanceLib.getAvailableAllowance(address(account));
    assertGt(beneficiary.balance, 0);
    assertEq(beneficiary.balance, feePaidByPaymaster);
    assertGt(feePaidByUser, 0);
    assertGt(feePaidByUser, feePaidByPaymaster);
  }

  function testCallWithPaymaster_PartialAllowanceAndBalance() external {
    vm.deal(address(account), 1e18);
    PackedUserOperation memory op = fillUserOp(
      account,
      userKey,
      address(counter),
      0,
      abi.encodeWithSelector(TestCounter.count.selector)
    );

    op.paymasterAndData = abi.encodePacked(address(paymaster), uint128(100000), uint128(100000));
    op.signature = signUserOp(op, userKey);

    // Grant partial allowance that's not enough to cover the full cost
    uint256 partialAllowance = 10_000; // About half of the required amount
    vm.prank(grantor);
    paymaster.grantAllowance(address(account), partialAllowance);
    assertEq(Balance.getBalance(grantor), sponsorBalance - partialAllowance);
    assertEq(AllowanceLib.getAvailableAllowance(address(account)), partialAllowance);

    // Deposit a balance that's more than enough to cover the entire cost
    uint256 balanceDeposit = 0.1 ether; // More than enough to cover the full cost
    vm.deal(address(account), balanceDeposit);
    vm.prank(address(account));
    paymaster.depositTo{ value: balanceDeposit }(address(account));
    assertEq(Balance.getBalance(address(account)), balanceDeposit);

    // Expect the user op to succeed with partial payment from both allowance and balance
    uint256 paymasterBalance = entryPoint.balanceOf(address(paymaster));
    assertEq(beneficiary.balance, 0);
    submitUserOp(op);
    uint256 feePaidByPaymaster = paymasterBalance - entryPoint.balanceOf(address(paymaster));
    uint256 remainingAllowance = AllowanceLib.getAvailableAllowance(address(account));
    uint256 remainingBalance = Balance.getBalance(address(account));

    // Verify that allowance was fully depleted before balance was used
    assertEq(remainingAllowance, 0, "Allowance should be fully depleted");
    assertLt(remainingBalance, balanceDeposit, "Balance should be reduced");
    assertGt(beneficiary.balance, 0);
    assertEq(beneficiary.balance, feePaidByPaymaster);

    // Calculate how much was taken from balance
    uint256 balanceUsed = balanceDeposit - remainingBalance;
    uint256 totalCost = partialAllowance + balanceUsed;
    assertGt(totalCost, partialAllowance, "Total cost should be more than the allowance");
    assertGt(totalCost, feePaidByPaymaster, "Total cost should be more than the fee paid by the paymaster");
  }

  function testCallWithSpender_BalanceOnly() external {
    PackedUserOperation memory op = fillUserOp(
      account,
      userKey,
      address(counter),
      0,
      abi.encodeWithSelector(TestCounter.count.selector)
    );

    op.paymasterAndData = abi.encodePacked(address(paymaster), uint128(100000), uint128(100000));
    op.signature = signUserOp(op, userKey);

    // Register the account as spender for the user
    vm.prank(user);
    paymaster.registerSpender(address(account));

    // Deposit balance to the user (not the spender account)
    uint256 balanceDeposit = 0.1 ether;
    vm.deal(user, balanceDeposit);
    vm.prank(user);
    paymaster.depositTo{ value: balanceDeposit }(user);
    assertEq(Balance.getBalance(user), balanceDeposit);

    // Expect the user op to succeed using only the user's balance
    uint256 paymasterBalance = entryPoint.balanceOf(address(paymaster));
    assertEq(beneficiary.balance, 0);
    submitUserOp(op);
    uint256 feePaidByPaymaster = paymasterBalance - entryPoint.balanceOf(address(paymaster));
    uint256 remainingBalance = Balance.getBalance(user);

    // Verify that balance was used and allowance wasn't touched
    assertLt(remainingBalance, balanceDeposit, "Balance should be reduced");
    assertEq(AllowanceLib.getAvailableAllowance(user), 0, "Allowance should remain at 0");
    assertGt(beneficiary.balance, 0);
    assertEq(beneficiary.balance, feePaidByPaymaster);

    // Calculate how much was taken from balance
    uint256 balanceUsed = balanceDeposit - remainingBalance;
    assertGt(balanceUsed, 0, "Some balance should have been used");
    assertGt(balanceUsed, feePaidByPaymaster, "Balance used should be more than the fee paid by paymaster");
  }

  function testCallWithSpender() external {
    vm.deal(address(account), 1e18);
    PackedUserOperation memory op = fillUserOp(
      account,
      userKey,
      address(counter),
      0,
      abi.encodeWithSelector(TestCounter.count.selector)
    );

    op.paymasterAndData = abi.encodePacked(address(paymaster), uint128(100000), uint128(100000));
    op.signature = signUserOp(op, userKey);

    // Grant sufficient computation units to the user
    uint256 requiredAllowance = 380000000000000;
    vm.prank(grantor);
    paymaster.grantAllowance(user, requiredAllowance);
    assertEq(Balance.getBalance(grantor), sponsorBalance - requiredAllowance);
    assertEq(AllowanceLib.getAvailableAllowance(user), requiredAllowance);

    // Expect the call to fail while the account is not a spender of the user
    expectUserOpRevert(
      abi.encodeWithSelector(
        PaymasterSystem.PaymasterSystem_InsufficientFunds.selector,
        address(account),
        uint256(380000000000000),
        uint256(0),
        uint256(0)
      )
    );
    submitUserOp(op);
    assertEq(AllowanceLib.getAvailableAllowance(address(user)), requiredAllowance);

    // Register the account as spender for the user
    vm.prank(user);
    paymaster.registerSpender(address(account));

    // Expect the user op to succeed now and the balance to be taken from the user account
    assertEq(beneficiary.balance, 0);
    submitUserOp(op);
    uint256 feePaidByPaymaster = sponsorBalance - entryPoint.balanceOf(address(paymaster));
    uint256 feePaidByUser = requiredAllowance - AllowanceLib.getAvailableAllowance(address(user));
    assertGt(beneficiary.balance, 0);
    assertEq(beneficiary.balance, feePaidByPaymaster);
    assertGt(feePaidByUser, 0);
    assertGt(feePaidByUser, feePaidByPaymaster);
  }

  function fillUserOp(
    SimpleAccount _sender,
    uint256 _key,
    address _to,
    uint256 _value,
    bytes memory _data
  ) internal view returns (PackedUserOperation memory op) {
    op.sender = address(_sender);
    op.nonce = entryPoint.getNonce(address(_sender), 0);
    op.callData = abi.encodeWithSelector(SimpleAccount.execute.selector, _to, _value, _data);
    op.accountGasLimits = bytes32(abi.encodePacked(bytes16(uint128(80000)), bytes16(uint128(50000))));
    op.preVerificationGas = 50000;
    op.gasFees = bytes32(abi.encodePacked(bytes16(uint128(100)), bytes16(uint128(1000000000))));
    // NOTE: gas fees are set to 0 on purpose to not require paymaster to have a deposit
    // op.gasFees = bytes32(abi.encodePacked(bytes16(uint128(0)), bytes16(uint128(0))));
    op.signature = signUserOp(op, _key);
    return op;
  }

  function signUserOp(PackedUserOperation memory op, uint256 _key) internal view returns (bytes memory signature) {
    bytes32 hash = entryPoint.getUserOpHash(op);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, MessageHashUtils.toEthSignedMessageHash(hash));
    signature = abi.encodePacked(r, s, v);
  }

  function submitUserOp(PackedUserOperation memory op) internal {
    PackedUserOperation[] memory ops = new PackedUserOperation[](1);
    ops[0] = op;
    entryPoint.handleOps(ops, beneficiary);
  }

  function expectUserOpRevert(bytes memory message) internal {
    vm.expectRevert(
      abi.encodeWithSelector(IEntryPoint.FailedOpWithRevert.selector, uint256(0), "AA33 reverted", message)
    );
  }
}
