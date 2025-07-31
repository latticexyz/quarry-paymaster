import { type } from "arktype";

const env = type({
  CHAIN_ID: "string",
  SPONSOR_PRIVATE_KEY: "string",
  ALLOWANCE_AMOUNT: "string",
  "PORT?": "string",
});

const result = env(process.env);
if (result instanceof type.errors) {
  console.error(process.env);
  throw new Error(result.summary);
}

export default { ...result };
