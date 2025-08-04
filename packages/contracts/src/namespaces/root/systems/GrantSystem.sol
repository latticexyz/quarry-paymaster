// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Balance } from "../codegen/tables/Balance.sol";
import { Allowance, AllowanceData } from "../codegen/tables/Allowance.sol";
import { AllowanceList, AllowanceListData } from "../codegen/tables/AllowanceList.sol";
import { AllowanceLib } from "./AllowanceSystem.sol";

uint256 constant MIN_ALLOWANCE = 0.00001 ether;
uint256 constant MAX_NUM_ALLOWANCES = 20;

// TODO: optimize to avoid updating the list multiple times per call

contract GrantSystem is System {
  error GrantSystem_AllowanceBelowMinimum(uint256 allowance, uint256 min);
  error GrantSystem_AllowancesLimitReached(uint256 length, uint256 max);
  error GrantSystem_InsufficientBalance(uint256 balance, uint256 required);

  function grantAllowance(address user, uint256 allowance) public payable {
    if (allowance < MIN_ALLOWANCE) {
      revert GrantSystem_AllowanceBelowMinimum(allowance, MIN_ALLOWANCE);
    }
    address sponsor = _msgSender();
    GrantLib.grantAllowance(user, sponsor, allowance);
  }
}

library GrantLib {

  function grantAllowance(address user, address sponsor, uint256 allowance) internal {
    uint256 balance = Balance._get(sponsor);
    if (balance < allowance) {
      revert GrantSystem.GrantSystem_InsufficientBalance(balance, allowance);
    }
    Balance._set({ user: sponsor, balance: balance - allowance });

    uint256 currentAllowance = Allowance._getAllowance({ user: user, sponsor: sponsor });
    if (currentAllowance > 0) {
      AllowanceLib.removeAllowance({ user: user, sponsor: sponsor, reclaim: true });
    }
    uint256 newAllowance = currentAllowance + allowance;

    AllowanceListData memory allowanceList = AllowanceList.get(user);
    if (allowanceList.length >= MAX_NUM_ALLOWANCES) {
      revert GrantSystem.GrantSystem_AllowancesLimitReached(allowanceList.length, MAX_NUM_ALLOWANCES);
    }

    // Find the last sponsor with an allowance less than the new allowance
    // and the first sponsor with an allowance greater than or equal to the new allowance
    address previousSponsor;
    address nextSponsor = allowanceList.first;
    AllowanceData memory nextItem = Allowance._get({ user: user, sponsor: nextSponsor });
    while (nextSponsor != address(0) && nextItem.allowance < newAllowance) {
      previousSponsor = nextSponsor;
      nextSponsor = nextItem.next;
      nextItem = Allowance._get({ user: user, sponsor: nextSponsor });
    }

    Allowance._set({
      user: user,
      sponsor: sponsor,
      allowance: newAllowance,
      next: nextSponsor,
      previous: previousSponsor
    });
    AllowanceList._setLength({ user: user, length: AllowanceList._getLength(user) + 1 });

    // Link the previous sponsor to the new sponsor
    if (previousSponsor == address(0)) {
      AllowanceList._setFirst({ user: user, first: sponsor });
    } else {
      Allowance._setNext({ user: user, sponsor: previousSponsor, next: sponsor });
    }

    // Link the next sponsor's previous link to the new sponsor
    if (nextSponsor != address(0)) {
      Allowance._setPrevious({ user: user, sponsor: nextSponsor, previous: sponsor });
    }
  }
}
