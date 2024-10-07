import Koa from "koa";
import cors from "@koa/cors";
import bodyParser from "@koa/bodyparser";
import { jsonRpc } from "./middleware/jsonRpc";
import { helloWorld } from "./middleware/helloWorld";
import { rest } from "./middleware/rest";

const server = new Koa();

server.use(cors());
server.use(helloWorld());
server.use(bodyParser());
server.use(jsonRpc());
server.use(rest());

console.log("Listening on port 80");
server.listen(80);
