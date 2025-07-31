import { type } from "arktype";
import { Hex, isHex } from "viem";

export const HexType = type("string").pipe.try((input): Hex => {
  if (isHex(input)) {
    return input;
  }

  throw new Error("must be a Hex string (`0x...`)");
});
