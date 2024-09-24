// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { EntryPoint } from "@account-abstraction/contracts/core/EntryPoint.sol";
import { PackedUserOperation } from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { SimpleAccountFactory, SimpleAccount } from "@account-abstraction/contracts/samples/SimpleAccountFactory.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

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
  SimpleAccount account;

  function setUp() public override {
    super.setUp();
    entryPoint = new EntryPoint();
    accountFactory = new SimpleAccountFactory(entryPoint);
    paymaster = IWorld(worldAddress);
    counter = new TestCounter();

    beneficiary = payable(makeAddr("beneficiary"));
    (user, userKey) = makeAddrAndKey("user");
    account = accountFactory.createAccount(user, 0);
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
    submitUserOp(op);
  }

  function testBalance() public {}

  function fillUserOp(
    SimpleAccount _sender,
    uint256 _key,
    address _to,
    uint256 _value,
    bytes memory _data
  ) public view returns (PackedUserOperation memory op) {
    op.sender = address(_sender);
    op.nonce = entryPoint.getNonce(address(_sender), 0);
    op.callData = abi.encodeWithSelector(SimpleAccount.execute.selector, _to, _value, _data);
    op.accountGasLimits = bytes32(abi.encodePacked(bytes16(uint128(80000)), bytes16(uint128(50000))));
    op.preVerificationGas = 50000;
    // NOTE: gas fees are set to 0 on purpose to not require paymaster to have a deposit
    op.gasFees = bytes32(abi.encodePacked(bytes16(uint128(0)), bytes16(uint128(0))));
    op.signature = signUserOp(op, _key);
    return op;
  }

  function signUserOp(PackedUserOperation memory op, uint256 _key) public view returns (bytes memory signature) {
    bytes32 hash = entryPoint.getUserOpHash(op);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, MessageHashUtils.toEthSignedMessageHash(hash));
    signature = abi.encodePacked(r, s, v);
  }

  function submitUserOp(PackedUserOperation memory op) public {
    PackedUserOperation[] memory ops = new PackedUserOperation[](1);
    ops[0] = op;
    entryPoint.handleOps(ops, beneficiary);
  }
}
