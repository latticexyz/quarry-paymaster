import express from "express";
import bodyParser from "body-parser";
import { handlers, jsonRpcRequest } from "./handlers";
import { type } from "arktype";

const app = express();
app.use(bodyParser.json());

app.post("/rpc", async (req, res) => {
  const request = jsonRpcRequest(req.body);

  if (request instanceof type.errors) {
    console.error(request.summary);
    res
      .send({
        error: {
          code: -32601,
          message: request.summary,
        },
      })
      .status(500);
    return;
  }

  const { namespace, method } = request.method;
  const { params } = request;

  try {
    const result = handlers[namespace][method](params);
    res.send(result).status(200);
  } catch (error) {
    res.send({ error }).status(500);
  }
});

console.log("Listening on port 80");
app.listen(80);
