import { type } from "arktype";
import { debug } from "./debug";

const env = type({
  CHAIN_ID: "string",
  SPONSOR_PRIVATE_KEY: "string",
  ALLOWANCE_AMOUNT: "string",
  "NAMESPACE?": "string",
  "PORT?": "string",
});

const result = env(process.env);
if (result instanceof type.errors) {
  console.error(process.env);
  throw new Error(result.summary);
}

debug(`Chain ID: ${result.CHAIN_ID}`);
debug(`Allowance amount: ${result.ALLOWANCE_AMOUNT}`);

export default { ...result };
