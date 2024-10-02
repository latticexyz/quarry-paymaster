// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { UserOperation } from "@account-abstraction/contracts/interfaces/UserOperation.sol";
import { Unstable_CallWithSignatureSystem } from "@latticexyz/world-modules/src/modules/callwithsignature/Unstable_CallWithSignatureModule.sol";
import { validateCallWithSignature } from "@latticexyz/world-modules/src/modules/callwithsignature/validateCallWithSignature.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { SimpleAccount } from "@account-abstraction/contracts/samples/SimpleAccount.sol";

/**
 * Recover the signer from a `callWithSignature` to this paymaster
 */
function recoverCallWithSignature(UserOperation calldata userOp) view returns (address) {
  // Require this to be a call to the smart account's `execute` function
  if (!isSimpleAccountExecuteCall(userOp)) {
    return address(0);
  }

  // Require the target of this `execute` call to be this contract
  if (getExecuteDestination(userOp) != WorldContextConsumerLib._world()) {
    return address(0);
  }

  // Extract the function payload from the `execute` call
  bytes calldata executeCallData = getExecuteCallData(userOp);

  // Require the target of this `execute` call to be `callWithSignature`
  if (getFunctionSelector(executeCallData) != Unstable_CallWithSignatureSystem.callWithSignature.selector) {
    return address(0);
  }

  // Validate the signature
  (address signer, ResourceId systemId, bytes memory callData, bytes memory signature) = abi.decode(
    getArguments(executeCallData),
    (address, ResourceId, bytes, bytes)
  );
  validateCallWithSignature(signer, systemId, callData, signature);

  return signer;
}

function isSimpleAccountExecuteCall(UserOperation calldata op) pure returns (bool) {
  return getFunctionSelector(op.callData) == SimpleAccount.execute.selector;
}

function getExecuteDestination(UserOperation calldata op) pure returns (address) {
  return address(uint160(uint256(bytes32(getArguments(op.callData)[0:32]))));
}

function getExecuteCallData(UserOperation calldata op) pure returns (bytes calldata) {
  // destination (32B) | value (32B) | first encoding length (32B) | second encoding length (32B) | call data bytes
  return getArguments(op.callData)[128:];
}

function getFunctionSelector(bytes calldata callData) pure returns (bytes4) {
  return bytes4(callData[0:4]);
}

function getArguments(bytes calldata callData) pure returns (bytes calldata) {
  return callData[4:];
}
