// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/console.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Allowance } from "../codegen/tables/Allowance.sol";
import { Grantor } from "../codegen/tables/Grantor.sol";

contract GrantSystem is System {
  error GrantSystem_InsufficientAllowance(address grantor, uint256 available, uint256 required);

  function grantAllowance(address user, uint256 allowance) public {
    address grantor = _msgSender();
    uint256 availableAllowance = Grantor._getAllowance(grantor);
    if (availableAllowance < allowance) {
      revert GrantSystem_InsufficientAllowance(grantor, availableAllowance, allowance);
    }
    Grantor._setAllowance(grantor, availableAllowance - allowance);
    uint256 currentAllowance = Allowance._get(user);
    Allowance._set(user, currentAllowance + allowance);
  }
}
