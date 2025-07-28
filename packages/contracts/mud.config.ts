import { defineWorld } from "@latticexyz/world";

const config = defineWorld({
  namespaces: {
    root: {
      namespace: "",
      tables: {
        // Balance gets deposited and is withdrawable
        Balance: {
          schema: {
            user: "address",
            balance: "uint256",
          },
          key: ["user"],
        },
        // Allowance gets granted and is not withdrawable
        Allowance: {
          schema: {
            user: "address",
            allowance: "uint256",
          },
          key: ["user"],
        },
        Spender: {
          schema: {
            spender: "address",
            user: "address",
          },
          key: ["spender"],
        },
        SystemConfig: {
          schema: {
            entryPoint: "address",
          },
          key: [],
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
  deploy: {
    upgradeableWorldImplementation: true,
    postDeployScript: "PostDeployKms.s.sol",
  },
});

export default config;
