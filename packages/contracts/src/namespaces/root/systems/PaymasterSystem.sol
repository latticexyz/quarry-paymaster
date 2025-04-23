// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IPaymaster } from "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import { PackedUserOperation } from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Allowance } from "../codegen/tables/Allowance.sol";
import { Balance } from "../codegen/tables/Balance.sol";
import { Spender } from "../codegen/tables/Spender.sol";
import { SystemConfig } from "../codegen/tables/SystemConfig.sol";
import { recoverCallWithSignature } from "../utils/recoverCallWithSignature.sol";

uint256 constant FIXED_POST_OP_GAS = 60_000;

contract PaymasterSystem is System, IPaymaster {
  error PaymasterSystem_InsufficientFunds(
    address user,
    uint256 maxCost,
    uint256 availableAllowance,
    uint256 availableBalance
  );
  error PaymasterSystem_OnlyEntryPoint();

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
    _requireFromEntryPoint();

    address user = _getUser(userOp);
    uint256 availableAllowance = Allowance._get(user);
    uint256 fromAllowance = maxCost;
    uint256 fromBalance = 0;

    if (fromAllowance > availableAllowance) {
      fromBalance = fromAllowance - availableAllowance;
      uint256 availableBalance = Balance._get(user);
      if (fromBalance > availableBalance) {
        revert PaymasterSystem_InsufficientFunds(user, maxCost, availableAllowance, availableBalance);
      }
      fromAllowance -= fromBalance;
      Balance._set(user, availableBalance - fromBalance);
    }

    Allowance._set(user, availableAllowance - fromAllowance);

    context = abi.encode(user, fromAllowance, fromBalance);
  }

  /**
   * Post-operation handler.
   * Must verify sender is the entryPoint.
   * @param mode          - Enum with the following options:
   *                        opSucceeded - User operation succeeded.
   *                        opReverted  - User op reverted. The paymaster still has to pay for gas.
   *                        postOpReverted - never passed in a call to postOp().
   * @param context       - The context value returned by validatePaymasterUserOp
   * @param actualGasCost - Actual cost of gas used so far (without this postOp call).
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
    _requireFromEntryPoint();

    (address user, uint256 fromAllowance, uint256 fromBalance) = abi.decode(context, (address, uint256, uint256));

    uint256 totalGasCost = actualGasCost + FIXED_POST_OP_GAS * actualUserOpFeePerGas;
    uint256 allowanceRefund; // always non-negative
    int256 balanceDiff; // may be negative if FIXED_POST_OP_GAS made the real cost exceed the deducted balance+allowance

    if (totalGasCost > fromAllowance) {
      // If FIXED_POST_OP_GAS made the total cost exceed the deducted balance+allowance,
      // we attempt to deduct the missing amount from the balance below.
      balanceDiff = int256(fromAllowance + fromBalance) - int256(totalGasCost);
    } else {
      allowanceRefund = fromAllowance - totalGasCost;
      balanceDiff = int256(fromBalance);
    }

    if (balanceDiff != 0) {
      uint256 currentBalance = Balance._get(user);
      int256 newBalance = int256(currentBalance) + balanceDiff;
      if (newBalance < 0) {
        revert PaymasterSystem_InsufficientFunds(
          user,
          totalGasCost,
          Allowance._get(user) + fromAllowance,
          currentBalance + fromBalance
        );
      }
      Balance._set(user, uint256(newBalance));
    }

    if (allowanceRefund > 0) {
      Allowance._set(user, Allowance._get(user) + allowanceRefund);
    }
  }

  /**
   * If this user op is sent from a spender account, translate it to the user account.
   * Else return the userOp sender.
   */
  function _getUser(PackedUserOperation calldata userOp) internal view returns (address) {
    // Check if this is a spender account
    address user = Spender.getUser(userOp.sender);
    if (user != address(0)) {
      return user;
    }

    // Check if this is a call to register a new spender via `callWithSignature`
    user = recoverCallWithSignature(userOp);
    if (user != address(0)) {
      return user;
    }

    return userOp.sender;
  }

  /**
   * Validate the call is made from a valid entrypoint
   */
  function _requireFromEntryPoint() internal virtual {
    if (_msgSender() != SystemConfig.getEntryPoint()) {
      revert PaymasterSystem_OnlyEntryPoint();
    }
  }
}
