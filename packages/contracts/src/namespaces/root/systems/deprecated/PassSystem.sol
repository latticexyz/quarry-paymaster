// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

/**
 * @notice Deprecated. Use the AllowanceSystem instead.
 */
contract PassSystem is System {
  function registerPass(bytes32, uint256, uint256, uint256) public pure {
    revert("The PassSystem is deprecated. Use the AllowanceSystem instead.");
  }

  function issuePass(bytes32, address) public pure {
    revert("The PassSystem is deprecated. Use the AllowanceSystem instead.");
  }

  function claimFor(address, bytes32) public pure {
    revert("The PassSystem is deprecated. Use the AllowanceSystem instead.");
  }
}
