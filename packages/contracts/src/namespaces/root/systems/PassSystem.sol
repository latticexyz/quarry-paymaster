// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Allowance } from "../codegen/tables/Allowance.sol";
import { Grantor } from "../codegen/tables/Grantor.sol";
import { PassConfig, PassConfigData } from "../codegen/tables/PassConfig.sol";
import { PassHolder, PassHolderData } from "../codegen/tables/PassHolder.sol";

contract PassSystem is System {
  error PassSystem_Unauthorized(bytes32 passId, address caller, address grantor);
  error PassSystem_PassExpired(bytes32 passId, uint256 validityPeriod, address user, uint256 lastRenewed);
  error PassSystem_PendingCooldown(bytes32 passId, uint256 claimInterval, address user, uint256 lastClaimed);
  error PassSystem_InsufficientGrantorAllowance(bytes32 passId, address grantor, uint256 allowance, uint256 required);

  /**
   * Register a new pass to allow users to claim allowance from the grantor.
   * @param passId A unique identifier for the pass
   * @param claimAmount The amount that can be claimed per claimInterval
   * @param claimInterval The cooldown time after a claim in seconds
   * @param validityPeriod The time a pass is valid for in seconds
   */
  function registerPass(bytes32 passId, uint256 claimAmount, uint256 claimInterval, uint256 validityPeriod) public {
    address caller = _msgSender();
    address existingGrantor = PassConfig._getGrantor(passId);
    if (existingGrantor != address(0) && existingGrantor != caller) {
      revert PassSystem_Unauthorized(passId, caller, existingGrantor);
    }

    PassConfig._set({
      passId: passId,
      claimAmount: claimAmount,
      claimInterval: claimInterval,
      validityPeriod: validityPeriod,
      grantor: caller
    });
  }

  /**
   * Issue a pass for a user. Requires the caller to be the pass' grantor.
   * @param passId The unique identifier of the pass to issue to the user
   * @param user The user to issue the pass for
   */
  function issuePass(bytes32 passId, address user) public {
    address caller = _msgSender();
    address grantor = PassConfig._getGrantor(passId);

    // Require the caller to be the pass' grantor
    if (caller != grantor) {
      revert PassSystem_Unauthorized(passId, caller, grantor);
    }

    PassHolder._set({ user: user, passId: passId, lastRenewed: block.timestamp, lastClaimed: 0 });
  }

  /**
   * Claim allowance from a pass for a user.
   * @param user The user to claim the allowance for
   * @param passId The unique identifier of the pass to claim for
   */
  function claimFor(address user, bytes32 passId) public {
    PassHolderData memory passHolder = PassHolder._get(user, passId);
    PassConfigData memory passConfig = PassConfig._get(passId);

    // Require the pass to be still valid
    if (block.timestamp > passHolder.lastRenewed + passConfig.validityPeriod) {
      revert PassSystem_PassExpired(passId, passConfig.validityPeriod, user, passHolder.lastRenewed);
    }

    // Require the last claim to have been before the claimInterval
    if (block.timestamp - passHolder.lastClaimed <= passConfig.claimInterval) {
      revert PassSystem_PendingCooldown(passId, passConfig.claimInterval, user, passHolder.lastClaimed);
    }

    // Require the grantor to have sufficient allowance
    uint256 grantorAllowance = Grantor._getAllowance(passConfig.grantor);
    if (grantorAllowance < passConfig.claimAmount) {
      revert PassSystem_InsufficientGrantorAllowance(
        passId,
        passConfig.grantor,
        grantorAllowance,
        passConfig.claimAmount
      );
    }

    // Deduct the amount from the grantor's allowance and add it to the user's allowance
    Grantor._setAllowance(passConfig.grantor, grantorAllowance - passConfig.claimAmount);
    Allowance._set(user, Allowance._get(user) + passConfig.claimAmount);
    PassHolder._setLastClaimed(user, passId, block.timestamp);
  }
}
