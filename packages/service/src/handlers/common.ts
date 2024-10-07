import { type } from "arktype";

export const namespace = type("'quarry'");
export const method = type("'claimAllowance' | 'issuePass'");
export const params = type("(string | number | boolean)[]");
export const parseParams = type("string").pipe((s) => JSON.parse(s), params);

export type Handler = (input: typeof params.infer) => Promise<unknown>;

export type Handlers = {
  [namespace in typeof namespace.infer]: {
    [method in typeof method.infer]: Handler;
  };
};
