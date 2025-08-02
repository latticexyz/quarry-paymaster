import Koa from "koa";
import cors from "@koa/cors";
import bodyParser from "@koa/bodyparser";
import { jsonRpc } from "./middleware/jsonRpc";
import { helloWorld } from "./middleware/helloWorld";
import { rest } from "./middleware/rest";
import env from "./env";
import { getSmartAccountClient } from "./clients";
import { setup } from "./setup";

const server = new Koa();

server.use(cors());
server.use(helloWorld());
server.use(bodyParser());
server.use(jsonRpc());
server.use(rest());

const port = Number(env.PORT ?? 3003);
console.log(`Listening on port ${port}`);
server.listen(port);

setup().catch((e) => {
  console.error(e);
  process.exit(1);
});

getSmartAccountClient().then(async (client) => console.log(`Sponsor account address: ${client.account.address}`));
