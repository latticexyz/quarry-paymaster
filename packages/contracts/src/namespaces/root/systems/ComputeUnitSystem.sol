// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/console.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ComputeUnits } from "../codegen/tables/ComputeUnits.sol";
import { ComputeUnitManager } from "../codegen/tables/ComputeUnitManager.sol";

contract ComputeUnitSystem is System {
  error ComputeUnitSystem_InsufficientAllowance(address manager, uint256 allowance);

  function addComputeUnits(address user, uint256 computeUnits) public {
    address manager = _msgSender();
    uint256 allowance = ComputeUnitManager._getAllowance(manager);
    if (allowance < computeUnits) {
      revert ComputeUnitSystem_InsufficientAllowance(manager, allowance);
    }
    ComputeUnitManager._setAllowance(manager, allowance - computeUnits);
    uint256 currentComputeUnits = ComputeUnits._get(user);
    ComputeUnits._set(user, currentComputeUnits + computeUnits);
  }
}
