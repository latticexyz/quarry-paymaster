// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console2 as console } from "forge-std/console2.sol";
import { AllowanceList } from "../../src/namespaces/root/codegen/tables/AllowanceList.sol";
import { Allowance, AllowanceData } from "../../src/namespaces/root/codegen/tables/Allowance.sol";

function printAllowance(address user) view {
  printAllowance(user, type(uint256).max);
}

function printAllowance(address user, uint256 limit) view {
  address sponsor = AllowanceList.getFirst(user);
  while (sponsor != address(0) && limit > 0) {
    AllowanceData memory allowanceItem = Allowance.get({ user: user, sponsor: sponsor });
    console.log("sponsor", sponsor);
    console.log("allowance", allowanceItem.allowance);
    console.log("previous", allowanceItem.previous);
    console.log("next", allowanceItem.next);
    console.log("--------------------------------");
    sponsor = allowanceItem.next;
    limit--;
  }
}
