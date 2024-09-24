import { defineWorld } from "@latticexyz/world";

const config = defineWorld({
  namespaces: {
    root: {
      namespace: "",
      tables: {
        ComputeUnits: {
          schema: {
            user: "address",
            units: "uint256",
          },
          key: ["user"],
        },
        ComputeUnitManager: {
          schema: {
            account: "address",
            allowance: "uint256",
          },
          key: ["account"],
        },
      },
    },
    world: {
      tables: {
        NamespaceOwner: {
          schema: {
            namespaceId: "ResourceId",
            owner: "address",
          },
          key: ["namespaceId"],
          deploy: {
            disabled: true,
          },
          codegen: {
            storeArgument: true,
          },
        },
        UserDelegationControl: {
          schema: {
            delegator: "address",
            delegatee: "address",
            delegationControlId: "ResourceId",
          },
          key: ["delegator", "delegatee"],
          deploy: {
            disabled: true,
          },
          codegen: {
            storeArgument: true,
          },
        },
      },
    },
  },
  userTypes: {
    ResourceId: {
      type: "bytes32",
      filePath: "@latticexyz/store/src/ResourceId.sol",
    },
  },
});

export default config;
