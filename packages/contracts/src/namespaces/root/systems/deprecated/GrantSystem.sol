// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

/**
 * @notice Deprecated. Use the AllowanceSystem instead.
 */
contract GrantSystem is System {
  function grantAllowance(address, uint256) public pure {
    revert("The GrantSystem is deprecated. Use the AllowanceSystem instead.");
  }
}
