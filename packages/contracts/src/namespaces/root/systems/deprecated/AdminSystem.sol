// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

/**
 * @notice Deprecated. Use the AllowanceSystem instead.
 */
contract AdminSystem is System {
  function setGrantAllowance(address, uint256) public pure {
    revert("The AdminSystem is deprecated. Use the AllowanceSystem instead.");
  }
}
