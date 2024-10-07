import { type } from "arktype";

const namespace = type("'quarry'");
const method = type("'claimAllowance' | 'issuePass'");

const jsonRpcMethods = type("string").pipe.try((jsonRpcMethod) => {
  const [namespace, method] = jsonRpcMethod.split("_");
  return { namespace, method };
}, type({ namespace, method }));

export const jsonRpcRequest = type({
  method: jsonRpcMethods,
  params: "(string | number | boolean)[]",
  id: "number",
  jsonrpc: "'2.0'",
});

type Handlers = {
  [namespace in typeof namespace.infer]: {
    [method in typeof method.infer]: (input: typeof jsonRpcRequest.infer.params) => Promise<unknown>;
  };
};

export const handlers = {
  quarry: {
    claimAllowance: async (input) => {
      console.log("quarry_claimAllowance", input);
      return { message: "success" };
    },
    issuePass: async (input) => {
      console.log("quarry_issuePass", input);
      return { message: "success" };
    },
  },
} satisfies Handlers;
