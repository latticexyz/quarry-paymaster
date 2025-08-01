// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console2 as console } from "forge-std/console2.sol";

//sample "receiver" contract, for testing "exec" from account.
contract TestCounter {
  mapping(address => uint256) public counters;

  function count() public {
    counters[msg.sender] = counters[msg.sender] + 1;
  }

  function countFail() public pure {
    revert("count failed");
  }

  function justemit() public {
    emit CalledFrom(msg.sender);
  }

  event CalledFrom(address sender);

  function spendGas(uint256 gasLimit) external view {
    uint256 initialGas = gasleft();
    while (initialGas - gasleft() < gasLimit) {}
  }
}
