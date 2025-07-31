import { type } from "arktype";

const env = type({
  CHAIN_ID: "string",
  ISSUER_PRIVATE_KEY: "string",
  "PORT?": "string",
});

const result = env(process.env);
if (result instanceof type.errors) {
  throw new Error(result.summary);
}

export default { ...result };
