import { type } from "arktype";
import { EIP1193Parameters, EIP1193RequestFn, Hex, isHex, RpcSchema } from "viem";

export const HexType = type("string").pipe.try((input): Hex => {
  if (isHex(input)) {
    return input;
  }

  throw new Error("must be a Hex string (`0x...`)");
});

export type TransportRequestFn<rpcSchema extends RpcSchema> = <
  args extends EIP1193Parameters<rpcSchema> = EIP1193Parameters<rpcSchema>,
  method extends Extract<rpcSchema[number], { Method: args["method"] }> = Extract<
    rpcSchema[number],
    { Method: args["method"] }
  >,
>(
  args: args,
  options?: Parameters<EIP1193RequestFn>[1],
) => Promise<method["ReturnType"]>;
