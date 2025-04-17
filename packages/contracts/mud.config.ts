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
        Grantor: {
          schema: {
            grantor: "address",
            allowance: "uint256",
          },
          key: ["grantor"],
        },
        PassHolder: {
          schema: {
            user: "address",
            passId: "bytes32",
            lastRenewed: "uint256",
            lastClaimed: "uint256",
          },
          key: ["user", "passId"],
        },
        PassConfig: {
          schema: {
            passId: "bytes32",
            claimAmount: "uint256",
            claimInterval: "uint256",
            validityPeriod: "uint256",
            grantor: "address",
          },
          key: ["passId"],
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
});

export default config;
