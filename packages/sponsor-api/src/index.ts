import Koa from "koa";
import cors from "@koa/cors";
import bodyParser from "@koa/bodyparser";
import { jsonRpc } from "./middleware/jsonRpc";
import { helloWorld } from "./middleware/helloWorld";
import { rest } from "./middleware/rest";
import env from "./env";
import { getSmartAccountClient } from "./clients";

const server = new Koa();

server.use(cors());
server.use(helloWorld());
server.use(bodyParser());
server.use(jsonRpc());
server.use(rest());

const port = Number(env.PORT ?? 3003);
console.log(`Listening on port ${port}`);
server.listen(port);
getSmartAccountClient().then((client) => console.log(`Executor account address: ${client.account.address}`));
