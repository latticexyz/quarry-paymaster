import { defineWorld } from "@latticexyz/world";

const config = defineWorld({
  namespaces: {
    root: {
      namespace: "",
      tables: {
        Allowance: {
          schema: {
            user: "address",
            allowance: "uint256",
          },
          key: ["user"],
        },
        Grantor: {
          schema: {
            grantor: "address",
            allowance: "uint256",
          },
          key: ["grantor"],
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
