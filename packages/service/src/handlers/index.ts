import { claimAllowance } from "./claimAllowance";
import { issuePass } from "./issuePass";
import { Handler, Handlers } from "./common";
export * from "./common";

export const handlers = {
  quarry: {
    claimAllowance,
    issuePass,
  },
} satisfies Handlers;

type GetHandlerInput = { namespace: string; method: string };

export function getHandler({ namespace, method }: GetHandlerInput): Handler | undefined {
  const namespaceHandlers = handlers[namespace as keyof typeof handlers];
  return namespaceHandlers && namespaceHandlers[method as keyof typeof namespaceHandlers];
}
