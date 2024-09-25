// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";

import { Grantor } from "../codegen/tables/Grantor.sol";

contract AdminSystem is System {
  function setGrantAllowance(address grantor, uint256 allowance) public {
    AccessControl._requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    Grantor._setAllowance(grantor, allowance);
  }
}
