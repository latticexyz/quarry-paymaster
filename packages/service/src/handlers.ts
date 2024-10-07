import { type } from "arktype";

export const namespace = type("'quarry'");
export const method = type("'claimAllowance' | 'issuePass'");
export const params = type("(string | number | boolean)[]");
export const parseParams = type("string").pipe((s) => JSON.parse(s), params);

type Handler = (input: typeof params.infer) => Promise<unknown>;

type Handlers = {
  [namespace in typeof namespace.infer]: {
    [method in typeof method.infer]: Handler;
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

type GetHandlerInput = { namespace: string; method: string };

export function getHandler({ namespace, method }: GetHandlerInput): Handler | undefined {
  const namespaceHandlers = handlers[namespace as keyof typeof handlers];
  return namespaceHandlers && namespaceHandlers[method as keyof typeof namespaceHandlers];
}
