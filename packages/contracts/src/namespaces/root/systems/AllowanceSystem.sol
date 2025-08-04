// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Balance } from "../codegen/tables/Balance.sol";
import { Allowance, AllowanceData } from "../codegen/tables/Allowance.sol";
import { AllowanceList, AllowanceListData } from "../codegen/tables/AllowanceList.sol";

// TODO: optimize to avoid updating the list multiple times per call

contract AllowanceSystem is System {
  error AllowanceSystem_InsufficientAllowance(uint256 allowance, uint256 required);
  error AllowanceSystem_NotAuthorized(address caller, address sponsor, address user);
  error AllowanceSystem_NotFound(address user, address sponsor);

  function removeAllowance(address user, address sponsor) public {
    address caller = _msgSender();
    if (caller != sponsor && caller != user) {
      revert AllowanceSystem_NotAuthorized(caller, sponsor, user);
    }
    AllowanceData memory allowance = Allowance._get({ user: user, sponsor: sponsor });
    if (allowance.allowance == 0) {
      revert AllowanceSystem_NotFound(user, sponsor);
    }
    AllowanceLib.removeAllowance({ user: user, sponsor: sponsor, reclaim: true });
  }

  function getAllowance(address user) public view returns (uint256) {
    return AllowanceLib.getAllowance(user);
  }
}

library AllowanceLib {
  function getMissingAllowance(address user, uint256 amount) internal view returns (uint256) {
    address sponsor = AllowanceList.getFirst(user);
    while (sponsor != address(0)) {
      AllowanceData memory allowanceItem = Allowance._get({ user: user, sponsor: sponsor });
      if (allowanceItem.allowance >= amount) {
        return 0;
      }
      amount -= allowanceItem.allowance;
      sponsor = allowanceItem.next;
    }
    return amount;
  }

  function getAllowance(address user) internal view returns (uint256) {
    address sponsor = AllowanceList._getFirst(user);
    uint256 available = 0;
    while (sponsor != address(0)) {
      AllowanceData memory allowanceItem = Allowance._get({ user: user, sponsor: sponsor });
      available += allowanceItem.allowance;
      sponsor = allowanceItem.next;
    }
    return available;
  }

  function spendAllowance(address user, uint256 amount) internal {
    while (amount > 0) {
      address sponsor = AllowanceList._getFirst(user);
      if (sponsor == address(0)) {
        revert AllowanceSystem.AllowanceSystem_InsufficientAllowance(0, amount);
      }

      AllowanceData memory allowanceItem = Allowance._get({ user: user, sponsor: sponsor });
      if (allowanceItem.allowance > amount) {
        Allowance._setAllowance({ user: user, sponsor: sponsor, allowance: allowanceItem.allowance - amount });
        return;
      }

      AllowanceLib.removeAllowance({ user: user, sponsor: sponsor, reclaim: false });
      amount -= allowanceItem.allowance;
    }
  }

  function removeAllowance(address user, address sponsor, bool reclaim) internal {
    AllowanceListData memory allowanceList = AllowanceList._get(user);
    AllowanceData memory removedItem = Allowance._get({ user: user, sponsor: sponsor });
    bool exists = allowanceList.first == sponsor ||
      removedItem.previous != address(0) ||
      removedItem.next != address(0);

    if (!exists) {
      revert AllowanceSystem.AllowanceSystem_NotFound(user, sponsor);
    }

    Allowance._deleteRecord({ user: user, sponsor: sponsor });
    AllowanceList._setLength({ user: user, length: allowanceList.length - 1 });
    if (reclaim) {
      Balance._set({ user: sponsor, balance: Balance._get(sponsor) + removedItem.allowance });
    }

    // If the removed item was the list's root, set the root to the next item
    if (allowanceList.first == sponsor) {
      AllowanceList._setFirst({ user: user, first: removedItem.next });
    } else if (removedItem.previous != address(0)) {
      // If the removed item had a previous item, link the previous item to the next item
      Allowance._setNext({ user: user, sponsor: removedItem.previous, next: removedItem.next });
    }

    // If the removed item had a next item, link the next item to the previous item
    if (removedItem.next != address(0)) {
      Allowance._setPrevious({ user: user, sponsor: removedItem.next, previous: removedItem.previous });
    }
  }
}
