// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Balance } from "../codegen/tables/Balance.sol";
import { Allowance, AllowanceData } from "../codegen/tables/Allowance.sol";
import { AllowanceList, AllowanceListData } from "../codegen/tables/AllowanceList.sol";
import { SystemConfig } from "../codegen/tables/SystemConfig.sol";
import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

uint256 constant MIN_ALLOWANCE = 0.00001 ether;
uint256 constant MAX_NUM_ALLOWANCES = 20;

// TODO: optimize to avoid updating the list multiple times per call

contract AllowanceSystem is System {
  error AllowanceSystem_AllowanceBelowMinimum(uint256 allowance, uint256 min);
  error AllowanceSystem_AllowancesLimitReached(uint256 length, uint256 max);
  error AllowanceSystem_InsufficientBalance(uint256 balance, uint256 allowance);
  error AllowanceSystem_NotAuthorized(address caller, address sponsor, address user);

  function grantAllowance(address user, uint256 allowance) public payable {
    if (allowance < MIN_ALLOWANCE) {
      revert AllowanceSystem_AllowanceBelowMinimum(allowance, MIN_ALLOWANCE);
    }
    address sponsor = _msgSender();
    AllowanceLib.grantAllowance(user, sponsor, allowance);
  }

  function removeAllowance(address user, address sponsor) public {
    address caller = _msgSender();
    if (caller != sponsor && caller != user) {
      revert AllowanceSystem_NotAuthorized(caller, sponsor, user);
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

  function grantAllowance(address user, address sponsor, uint256 allowance) internal {
    uint256 balance = Balance._get(sponsor);
    if (balance < allowance) {
      revert AllowanceSystem.AllowanceSystem_InsufficientBalance(balance, allowance);
    }
    Balance._set({ user: sponsor, balance: balance - allowance });

    uint256 newAllowance = Allowance._getAllowance({ user: user, sponsor: sponsor }) + allowance;

    AllowanceLib.removeAllowance({ user: user, sponsor: sponsor, reclaim: true });

    AllowanceListData memory allowanceList = AllowanceList.get(user);
    if (allowanceList.length >= MAX_NUM_ALLOWANCES) {
      revert AllowanceSystem.AllowanceSystem_AllowancesLimitReached(allowanceList.length, MAX_NUM_ALLOWANCES);
    }

    // Find the last sponsor with an allowance less than the new allowance and
    // the first sponsor with an allowance greater than or equal to the new allowance
    address previousSponsor;
    address nextSponsor = allowanceList.first;
    AllowanceData memory nextItem = Allowance._get({ user: user, sponsor: nextSponsor });
    while (nextSponsor != address(0) && nextItem.allowance < newAllowance) {
      previousSponsor = nextSponsor;
      nextSponsor = nextItem.next;
      nextItem = Allowance._get({ user: user, sponsor: nextSponsor });
    }

    Allowance._set({ user: user, sponsor: sponsor, allowance: newAllowance, next: nextSponsor });
    AllowanceList._setLength({ user: user, length: AllowanceList._getLength(user) + 1 });

    // Link the previous sponsor to the new sponsor
    if (previousSponsor == address(0)) {
      AllowanceList._setFirst({ user: user, first: sponsor });
    } else {
      Allowance._setNext({ user: user, sponsor: previousSponsor, next: sponsor });
    }

    // Link the new sponsor to the next sponsor
    if (nextSponsor != address(0)) {
      Allowance._setNext({ user: user, sponsor: sponsor, next: nextSponsor });
    }
  }

  function spendAllowance(address user, uint256 amount) internal returns (uint256 missingAmount) {
    while (amount > 0) {
      address sponsor = AllowanceList._getFirst(user);
      if (sponsor == address(0)) {
        return amount;
      }

      AllowanceData memory allowanceItem = Allowance._get({ user: user, sponsor: sponsor });
      if (allowanceItem.allowance > amount) {
        Allowance._setAllowance({ user: user, sponsor: sponsor, allowance: allowanceItem.allowance - amount });
        return 0;
      }

      AllowanceLib.removeAllowance({ user: user, sponsor: sponsor, reclaim: false });
      amount -= allowanceItem.allowance;
    }
  }

  function removeAllowance(address user, address sponsor, bool reclaim) internal {
    AllowanceListData memory allowanceList = AllowanceList._get(user);
    if (allowanceList.length == 0) {
      return;
    }

    AllowanceData memory removedItem = Allowance._get({ user: user, sponsor: sponsor });
    if (removedItem.allowance == 0 && removedItem.next == address(0)) {
      return;
    }

    Allowance._deleteRecord({ user: user, sponsor: sponsor });
    AllowanceList._setLength({ user: user, length: allowanceList.length - 1 });
    if (reclaim) {
      Balance._set({ user: sponsor, balance: Balance._get(sponsor) + removedItem.allowance });
    }

    // If the removed item was the list's root, set the root to the next item
    if (allowanceList.first == sponsor) {
      AllowanceList._setFirst({ user: user, first: removedItem.next });
      return;
    }

    // Link the previous item to the next item
    address previousSponsor = allowanceList.first;
    AllowanceData memory previousItem = Allowance._get({ user: user, sponsor: previousSponsor });
    while (previousItem.next != sponsor) {
      previousSponsor = previousItem.next;
      previousItem = Allowance._get({ user: user, sponsor: previousSponsor });
    }
    Allowance._setNext({ user: user, sponsor: previousSponsor, next: removedItem.next });
  }
}
