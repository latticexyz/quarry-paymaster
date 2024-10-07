import { Middleware } from "koa";
import Router from "@koa/router";
import compose from "koa-compose";
import { getHandler, params } from "../handlers";
import { type } from "arktype";

export const parseQuery = type({ "params?": params });

export function rest(): Middleware {
  const router = new Router();

  router.get("/api/:namespace/:method", async (ctx) => {
    const { namespace, method } = ctx.params;
    if (!namespace || !method) {
      ctx.status = 404;
      return;
    }

    const handler = getHandler({ namespace, method });
    if (!handler) {
      ctx.status = 404;
      return;
    }

    const query = parseQuery(ctx.request.query);
    if (query instanceof type.errors) {
      ctx.status = 400;
      ctx.body = { error: query.summary };
      return;
    }

    try {
      const result = await handler(query.params ?? []);
      ctx.status = 200;
      ctx.body = { result };
      return;
    } catch (error) {
      ctx.status = 500;
      ctx.body = { error: String(error) };
      return;
    }
  });

  return compose([router.routes(), router.allowedMethods()]) as Middleware;
}
