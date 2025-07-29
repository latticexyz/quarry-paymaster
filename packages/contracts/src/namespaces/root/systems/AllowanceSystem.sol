// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Balance } from "../codegen/tables/Balance.sol";
import { Allowance, AllowanceData } from "../codegen/tables/Allowance.sol";
import { AllowanceList, AllowanceListData } from "../codegen/tables/AllowanceList.sol";
import { SystemConfig } from "../codegen/tables/SystemConfig.sol";
import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

uint256 constant MIN_ALLOWANCE = 0.00001 ether;
uint256 constant MAX_NUM_ALLOWANCES = 10;

// TODO: optimize to avoid updating the list multiple times per call

contract AllowanceSystem is System {
  error AllowanceSystem_AllowanceBelowMinimum(uint256 allowance, uint256 min);
  error AllowanceSystem_AllowancesLimitReached(uint256 length, uint256 max);
  error AllowanceSystem_InsufficientBalance(uint256 balance, uint256 allowance);
  error AllowanceSystem_NotAuthorized(address caller, address sponsor, address user);
  error AllowanceSystem_InsufficientAllowance(uint256 required);

  function grantAllowance(address user, uint256 allowance) public payable {
    address sponsor = _msgSender();

    if (allowance < MIN_ALLOWANCE) {
      revert AllowanceSystem_AllowanceBelowMinimum(allowance, MIN_ALLOWANCE);
    }

    AllowanceListData memory allowanceList = AllowanceList.get(user);
    if (allowanceList.length >= MAX_NUM_ALLOWANCES) {
      revert AllowanceSystem_AllowancesLimitReached(allowanceList.length, MAX_NUM_ALLOWANCES);
    }

    // Take allowance from sponsor's balance
    uint256 balance = Balance.get(sponsor);
    if (balance < allowance) {
      revert AllowanceSystem_InsufficientBalance(balance, allowance);
    }
    Balance.set({ user: sponsor, balance: balance - allowance });

    uint256 newAllowance = Allowance.getAllowance({ user: user, sponsor: sponsor }) + allowance;

    _removeAllowance({ user: user, sponsor: sponsor, reclaim: true });

    // Find the last sponsor with an allowance less than the new allowance and
    // the first sponsor with an allowance greater than or equal to the new allowance
    address previousSponsor;
    address nextSponsor = allowanceList.first;
    AllowanceData memory nextItem = Allowance.get(user, nextSponsor);
    while (nextItem.next != address(0) && nextItem.allowance < newAllowance) {
      previousSponsor = nextSponsor;
      nextSponsor = nextItem.next;
      nextItem = Allowance.get(user, nextSponsor);
    }

    Allowance.set({ user: user, sponsor: sponsor, allowance: newAllowance, next: nextSponsor });
    AllowanceList.setLength({ user: user, length: AllowanceList.getLength(user) + 1 });

    // Link the previous sponsor to the new sponsor
    if (previousSponsor == address(0)) {
      AllowanceList.setFirst({ user: user, first: sponsor });
    } else {
      Allowance.setNext({ user: user, sponsor: previousSponsor, next: sponsor });
    }

    // Link the new sponsor to the next sponsor
    if (nextSponsor != address(0)) {
      Allowance.setNext({ user: user, sponsor: sponsor, next: nextSponsor });
    }
  }

  function removeAllowance(address user, address sponsor) public {
    address caller = _msgSender();
    if (caller != sponsor && caller != user) {
      revert AllowanceSystem_NotAuthorized(caller, sponsor, user);
    }
    _removeAllowance({ user: user, sponsor: sponsor, reclaim: true });
  }

  function _removeAllowance(address user, address sponsor, bool reclaim) internal {
    AllowanceListData memory allowanceList = AllowanceList.get(user);
    if (allowanceList.length == 0) {
      return;
    }

    AllowanceData memory removedItem = Allowance.get({ user: user, sponsor: sponsor });
    if (removedItem.allowance == 0) {
      return;
    }

    Allowance.deleteRecord({ user: user, sponsor: sponsor });
    AllowanceList.setLength({ user: user, length: allowanceList.length - 1 });
    if (reclaim) {
      Balance.set({ user: sponsor, balance: Balance.get(sponsor) + removedItem.allowance });
    }

    // If the removed item was the list's root, set the root to the next item
    if (allowanceList.first == sponsor) {
      AllowanceList.setFirst({ user: user, first: removedItem.next });
      return;
    }

    // Link the previous item to the next item
    address previousSponsor = allowanceList.first;
    AllowanceData memory previousItem = Allowance.get({ user: user, sponsor: previousSponsor });
    while (previousItem.next != sponsor) {
      previousSponsor = previousItem.next;
      previousItem = Allowance.get({ user: user, sponsor: previousSponsor });
    }
    Allowance.setNext({ user: user, sponsor: previousSponsor, next: removedItem.next });
  }

  function spendAllowance(address user, uint256 amount) public {
    while (amount > 0) {
      address sponsor = AllowanceList.getFirst(user);
      if (sponsor == address(0)) {
        revert AllowanceSystem_InsufficientAllowance(amount);
      }

      AllowanceData memory allowanceItem = Allowance.get({ user: user, sponsor: sponsor });
      if (allowanceItem.allowance > amount) {
        Allowance.setAllowance({ user: user, sponsor: sponsor, allowance: allowanceItem.allowance - amount });
        return;
      }

      _removeAllowance({ user: user, sponsor: sponsor, reclaim: false });
      amount -= allowanceItem.allowance;
    }
  }
}
