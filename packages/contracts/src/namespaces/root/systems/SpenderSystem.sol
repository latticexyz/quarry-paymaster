// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Spender } from "../codegen/tables/Spender.sol";
import { Allowance } from "../codegen/tables/Allowance.sol";
import { Balance } from "../codegen/tables/Balance.sol";

contract SpenderSystem is System {
  error SpenderSystem_AlreadyRegistered(address spender, address user);
  error SpenderSystem_HasOwnBalance(address spender);

  /**
   * Register a new spender to spend the user's allowance
   */
  function registerSpender(address spender) public {
    address user = _msgSender();
    address existingUser = Spender._getUser(spender);

    // Require the spender to not be registered as spender for a user already
    if (existingUser != address(0)) {
      revert SpenderSystem_AlreadyRegistered(spender, user);
    }

    // Require the spender account to not have own balance.
    // A spender always spends from the user allowance, so registering an
    // account with own allowance as spender would lock its allowance.
    if (Allowance._get(spender) > 0 || Balance._get(spender) > 0) {
      revert SpenderSystem_HasOwnBalance(spender);
    }

    Spender._setUser(spender, user);
  }
}
