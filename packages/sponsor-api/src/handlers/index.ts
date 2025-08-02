import { Handler, Handlers } from "./common";
import { requestAllowance } from "./requestAllowance";
export * from "./common";

export const handlers = {
  sponsor: {
    requestAllowance,
  },
} satisfies Handlers;

type GetHandlerInput = { namespace: string; method: string };

export function getHandler({ namespace, method }: GetHandlerInput): Handler | undefined {
  const namespaceHandlers = handlers[namespace as keyof typeof handlers];
  return namespaceHandlers && namespaceHandlers[method as keyof typeof namespaceHandlers];
}
