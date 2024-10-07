import { type } from "arktype";
import { handlers, method, namespace, params } from "../handlers";
import { Middleware } from "koa";
import Router from "@koa/router";
import compose from "koa-compose";

const jsonRpcMethods = type("string").pipe.try((jsonRpcMethod) => {
  const [namespace, method] = jsonRpcMethod.split("_");
  return { namespace, method };
}, type({ namespace, method }));

const jsonRpcRequest = type({
  method: jsonRpcMethods,
  params,
  id: "number",
  jsonrpc: "'2.0'",
});

export function jsonRpc(): Middleware {
  const router = new Router();

  router.post("/rpc", async (ctx) => {
    const request = jsonRpcRequest(ctx.request.body);
    if (request instanceof type.errors) {
      console.error(request.summary);

      ctx.status = 500;
      ctx.body = {
        // https://www.jsonrpc.org/specification#error_object
        id: ctx.request.body.id ?? null,
        jsonrpc: "2.0",
        error: {
          code: -32601,
          message: request.summary,
        },
      };

      return;
    }

    const { namespace, method } = request.method;
    const { params } = request;

    try {
      const result = await handlers[namespace][method](params);
      ctx.status = 200;
      ctx.body = {
        // https://www.jsonrpc.org/specification
        id: request.id,
        jsonrpc: "2.0",
        result,
      };
    } catch (error) {
      ctx.status = 500;
      ctx.body = {
        // https://www.jsonrpc.org/specification#error_object
        id: request.id,
        jsonrpc: "2.0",
        error: {
          code: -32603,
          message: String(error),
        },
      };
    }
  });

  return compose([router.routes(), router.allowedMethods()]) as Middleware;
}
