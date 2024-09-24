import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  tables: {
    ComputeUnits: {
      schema: {
        user: "address",
        units: "uint256",
      },
      key: ["user"],
    },
  },
});
