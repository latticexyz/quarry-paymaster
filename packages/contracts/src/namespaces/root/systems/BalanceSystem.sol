// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Balance } from "../codegen/tables/Balance.sol";
import { SystemConfig } from "../codegen/tables/SystemConfig.sol";
import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

uint256 constant MAX_BALANCE = 0.1 ether;

contract BalanceSystem is System {
  error BalanceSystem_BalanceTooHigh(address user, uint256 balance, uint256 max);
  error BalanceSystem_InsufficientBalance(address user, uint256 amount, uint256 balance);

  function depositTo(address to) public payable {
    uint256 balance = Balance._get(to) + _msgValue();

    if (balance > MAX_BALANCE) {
      revert BalanceSystem_BalanceTooHigh(to, balance, MAX_BALANCE);
    }

    Balance._set(to, balance);
    IEntryPoint(SystemConfig.getEntryPoint()).depositTo{ value: _msgValue() }(address(this));
  }

  function withdrawTo(address payable to, uint256 amount) public {
    address user = _msgSender();
    uint256 balance = Balance._get(user);

    if (amount > balance) {
      revert BalanceSystem_InsufficientBalance(user, amount, balance);
    }

    Balance._set(user, balance - amount);
    IEntryPoint(SystemConfig.getEntryPoint()).withdrawTo(to, amount);
  }
}
