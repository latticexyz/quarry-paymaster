// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

// Import store internals
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
import { Memory } from "@latticexyz/store/src/Memory.sol";
import { SliceLib } from "@latticexyz/store/src/Slice.sol";
import { EncodeArray } from "@latticexyz/store/src/tightcoder/EncodeArray.sol";
import { FieldLayout } from "@latticexyz/store/src/FieldLayout.sol";
import { Schema } from "@latticexyz/store/src/Schema.sol";
import { EncodedLengths, EncodedLengthsLib } from "@latticexyz/store/src/EncodedLengths.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

struct PassHolderData {
  uint256 lastRenewed;
  uint256 lastClaimed;
}

library PassHolder {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "", name: "PassHolder", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x7462000000000000000000000000000050617373486f6c646572000000000000);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x0040020020200000000000000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (address, bytes32)
  Schema constant _keySchema = Schema.wrap(0x00340200615f0000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (uint256, uint256)
  Schema constant _valueSchema = Schema.wrap(0x004002001f1f0000000000000000000000000000000000000000000000000000);

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](2);
    keyNames[0] = "user";
    keyNames[1] = "passId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](2);
    fieldNames[0] = "lastRenewed";
    fieldNames[1] = "lastClaimed";
  }

  /**
   * @notice Register the table with its config.
   */
  function register() internal {
    StoreSwitch.registerTable(_tableId, _fieldLayout, _keySchema, _valueSchema, getKeyNames(), getFieldNames());
  }

  /**
   * @notice Register the table with its config.
   */
  function _register() internal {
    StoreCore.registerTable(_tableId, _fieldLayout, _keySchema, _valueSchema, getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get lastRenewed.
   */
  function getLastRenewed(address user, bytes32 passId) internal view returns (uint256 lastRenewed) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get lastRenewed.
   */
  function _getLastRenewed(address user, bytes32 passId) internal view returns (uint256 lastRenewed) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Set lastRenewed.
   */
  function setLastRenewed(address user, bytes32 passId, uint256 lastRenewed) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((lastRenewed)), _fieldLayout);
  }

  /**
   * @notice Set lastRenewed.
   */
  function _setLastRenewed(address user, bytes32 passId, uint256 lastRenewed) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((lastRenewed)), _fieldLayout);
  }

  /**
   * @notice Get lastClaimed.
   */
  function getLastClaimed(address user, bytes32 passId) internal view returns (uint256 lastClaimed) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get lastClaimed.
   */
  function _getLastClaimed(address user, bytes32 passId) internal view returns (uint256 lastClaimed) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Set lastClaimed.
   */
  function setLastClaimed(address user, bytes32 passId, uint256 lastClaimed) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((lastClaimed)), _fieldLayout);
  }

  /**
   * @notice Set lastClaimed.
   */
  function _setLastClaimed(address user, bytes32 passId, uint256 lastClaimed) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    StoreCore.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((lastClaimed)), _fieldLayout);
  }

  /**
   * @notice Get the full data.
   */
  function get(address user, bytes32 passId) internal view returns (PassHolderData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    (bytes memory _staticData, EncodedLengths _encodedLengths, bytes memory _dynamicData) = StoreSwitch.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Get the full data.
   */
  function _get(address user, bytes32 passId) internal view returns (PassHolderData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    (bytes memory _staticData, EncodedLengths _encodedLengths, bytes memory _dynamicData) = StoreCore.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function set(address user, bytes32 passId, uint256 lastRenewed, uint256 lastClaimed) internal {
    bytes memory _staticData = encodeStatic(lastRenewed, lastClaimed);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(address user, bytes32 passId, uint256 lastRenewed, uint256 lastClaimed) internal {
    bytes memory _staticData = encodeStatic(lastRenewed, lastClaimed);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(address user, bytes32 passId, PassHolderData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.lastRenewed, _table.lastClaimed);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(address user, bytes32 passId, PassHolderData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.lastRenewed, _table.lastClaimed);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Decode the tightly packed blob of static data using this table's field layout.
   */
  function decodeStatic(bytes memory _blob) internal pure returns (uint256 lastRenewed, uint256 lastClaimed) {
    lastRenewed = (uint256(Bytes.getBytes32(_blob, 0)));

    lastClaimed = (uint256(Bytes.getBytes32(_blob, 32)));
  }

  /**
   * @notice Decode the tightly packed blobs using this table's field layout.
   * @param _staticData Tightly packed static fields.
   *
   *
   */
  function decode(
    bytes memory _staticData,
    EncodedLengths,
    bytes memory
  ) internal pure returns (PassHolderData memory _table) {
    (_table.lastRenewed, _table.lastClaimed) = decodeStatic(_staticData);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(address user, bytes32 passId) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(address user, bytes32 passId) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(uint256 lastRenewed, uint256 lastClaimed) internal pure returns (bytes memory) {
    return abi.encodePacked(lastRenewed, lastClaimed);
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    uint256 lastRenewed,
    uint256 lastClaimed
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData = encodeStatic(lastRenewed, lastClaimed);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(address user, bytes32 passId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(uint160(user)));
    _keyTuple[1] = passId;

    return _keyTuple;
  }
}
