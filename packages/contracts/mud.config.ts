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
        // Allowance is organized as a linked list and gets spent from smallest to largest
        Allowance: {
          name: "AllowanceV2",
          schema: {
            user: "address",
            sponsor: "address",
            allowance: "uint256",
            next: "address",
            previous: "address",
          },
          key: ["user", "sponsor"],
        },
        AllowanceList: {
          schema: {
            user: "address",
            first: "address",
            length: "uint256",
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
