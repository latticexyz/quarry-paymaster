// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/console.sol";
import { IPaymaster } from "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import { PackedUserOperation } from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { SimpleAccount } from "@account-abstraction/contracts/samples/SimpleAccount.sol";
import { IWorldCall } from "@latticexyz/world/src/IWorldKernel.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { Unstable_CallWithSignatureSystem } from "@latticexyz/world-modules/src/modules/callwithsignature/Unstable_CallWithSignatureModule.sol";
import { validateCallWithSignature } from "@latticexyz/world-modules/src/modules/callwithsignature/validateCallWithSignature.sol";

import { Allowance } from "../codegen/tables/Allowance.sol";
import { Delegation } from "../codegen/tables/Delegation.sol";

/**
 * TODO:
 * - There is a griefing attack vector in which Alice declares a delegation for Bob,
 *   but Alice doesn't have an allowance, so now if Bob wants to send a user operation
 *   it fails because only Alice's balance is checked. To prevent this, we should prevent
 *   registering a delegation for a spender that already has a delegation, and set the user as its own spender
 */

contract PaymasterSystem is System, IPaymaster {
  using SimpleAccountUserOperationLib for PackedUserOperation;
  error InsufficientAllowance(uint256 available, uint256 required);

  /**
   * Payment validation: check if paymaster agrees to pay.
   * Must verify sender is the entryPoint.
   * Revert to reject this request.
   * Note that bundlers will reject this method if it changes the state, unless the paymaster is trusted (whitelisted).
   * The paymaster pre-pays using its deposit, and receive back a refund after the postOp method returns.
   * @param userOp          - The user operation.
   * @param userOpHash      - Hash of the user's request data.
   * @param maxCost         - The maximum cost of this transaction (based on maximum gas and gas price from userOp).
   * @return context        - Value to send to a postOp. Zero length to signify postOp is not required.
   * @return validationData - Signature and time-range of this operation, encoded the same as the return
   *                          value of validateUserOperation.
   *                          <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
   *                                                    other values are invalid for paymaster.
   *                          <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
   *                          <6-byte> validAfter - first timestamp this operation is valid
   *                          Note that the validation code cannot use block.timestamp (or block.number) directly.
   */
  function validatePaymasterUserOp(
    PackedUserOperation calldata userOp,
    bytes32 userOpHash,
    uint256 maxCost
  ) public override returns (bytes memory context, uint256 validationData) {
    // TODO: verify the call is coming from the entry point contract
    address user = _getUser(userOp);
    uint256 availableAllowance = Allowance._get(user);

    if (availableAllowance < maxCost) {
      revert InsufficientAllowance(availableAllowance, maxCost);
    }

    Allowance._set(user, availableAllowance - maxCost);

    context = abi.encode(user, maxCost);
  }

  /**
   * Post-operation handler.
   * Must verify sender is the entryPoint.
   * @param mode          - Enum with the following options:
   *                        opSucceeded - User operation succeeded.
   *                        opReverted  - User op reverted. The paymaster still has to pay for gas.
   *                        postOpReverted - never passed in a call to postOp().
   * @param context       - The context value returned by validatePaymasterUserOp
   * @param actualGasCost - Actual gas used so far (without this postOp call).
   * @param actualUserOpFeePerGas - the gas price this UserOp pays. This value is based on the UserOp's maxFeePerGas
   *                        and maxPriorityFee (and basefee)
   *                        It is not the same as tx.gasprice, which is what the bundler pays.
   */
  function postOp(
    IPaymaster.PostOpMode mode,
    bytes calldata context,
    uint256 actualGasCost,
    uint256 actualUserOpFeePerGas
  ) public override {
    // TODO: verify the call is coming from the entry point contract
    (address user, uint256 maxCost) = abi.decode(context, (address, uint256));

    // Refund the unused cost
    uint256 currentAllowance = Allowance._get(user);
    Allowance._set(user, currentAllowance + maxCost - actualGasCost);
  }

  function _getUser(PackedUserOperation calldata userOp) internal view returns (address user) {
    // Check if there is an active delegation for this account
    address delegator = Delegation.getDelegator(userOp.sender);
    if (delegator != address(0)) {
      return delegator;
    }

    // Check if this is a call to register a new delegation via `callWithSignature`
    delegator = _recoverCallWithSignature(userOp);
    if (delegator != address(0)) {
      return delegator;
    }

    return userOp.sender;
  }

  /**
   * Recover the signer from a `callWithSignature` to this paymaster
   */
  function _recoverCallWithSignature(PackedUserOperation calldata userOp) internal view returns (address) {
    // Require this to be a call to the smart account's `execute` function
    if (!userOp.isExecuteCall()) {
      return address(0);
    }

    // Require the target of this `execute` call to be this contract
    if (userOp.getExecuteDestination() != _world()) {
      return address(0);
    }

    // Extract the function payload from the `execute` call
    bytes calldata executeCallData = userOp.getExecuteCallData();

    // Require the target of this `execute` call to be `callWithSignature`
    if (getFunctionSelector(executeCallData) != Unstable_CallWithSignatureSystem.callWithSignature.selector) {
      return address(0);
    }

    // Validate the signature
    (address signer, ResourceId systemId, bytes memory callData, bytes memory signature) = abi.decode(
      getArguments(executeCallData),
      (address, ResourceId, bytes, bytes)
    );
    validateCallWithSignature(signer, systemId, callData, signature);

    return signer;
  }
}

// Extract arguments from SimpleAccount.execute call
library SimpleAccountUserOperationLib {
  function isExecuteCall(PackedUserOperation calldata op) internal pure returns (bool) {
    return getFunctionSelector(op.callData) == SimpleAccount.execute.selector;
  }

  function getExecuteDestination(PackedUserOperation calldata op) internal pure returns (address) {
    return address(uint160(uint256(bytes32(getArguments(op.callData)[0:32]))));
  }

  function getExecuteCallData(PackedUserOperation calldata op) internal pure returns (bytes calldata) {
    // destination (32B) | value (32B) | first encoding length (32B) | second encoding length (32B) | call data bytes
    return getArguments(op.callData)[128:];
  }
}

function getFunctionSelector(bytes calldata callData) pure returns (bytes4) {
  return bytes4(callData[0:4]);
}

function getArguments(bytes calldata callData) pure returns (bytes calldata) {
  return callData[4:];
}
