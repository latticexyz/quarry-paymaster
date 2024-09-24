// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/console.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";

import { ComputeUnitManager } from "../codegen/tables/ComputeUnitManager.sol";

contract AdminSystem is System {
  function setComputeUnitManagerAllowance(address manager, uint256 allowance) public {
    AccessControl._requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    ComputeUnitManager._setAllowance(manager, allowance);
  }
}
