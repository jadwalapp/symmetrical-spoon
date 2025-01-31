import fastify, { type RouteShorthandOptions } from "fastify";
import { WhatsappService } from "./src/services/whatsapp/whatsapp_service";
import mongoose from "mongoose";
import { getConfig } from "./src/config/config";

async function main() {
  const cfg = getConfig();

  const mongooseConn = await mongoose.connect(cfg.mongodb.uri, {
    dbName: cfg.mongodb.database,
  });
  const whatsappService = new WhatsappService(mongooseConn);

  const app = fastify();

  app.get("/health", (req, res) => {
    res.status(200).send("ok");
  });

  const wasappInitializeOpts: RouteShorthandOptions = {
    schema: {
      body: {
        type: "object",
        properties: {
          customerId: { type: "string" },
          phoneNumber: { type: "string" },
        },
        required: ["customerId", "phoneNumber"],
      },
      response: {
        200: {
          type: "object",
          properties: {
            pairingCode: { type: "string" },
          },
        },
        500: {
          type: "object",
          properties: {
            error: { type: "string" },
          },
        },
      },
    },
  };
  app.post("/wasapp/initialize", wasappInitializeOpts, async (req, res) => {
    try {
      const { customerId, phoneNumber } = req.body as {
        customerId: string;
        phoneNumber: string;
      };

      const pairingCode = await whatsappService.initialize(
        customerId,
        phoneNumber
      );

      res.send({ pairingCode: pairingCode });
    } catch (error) {
      res.status(500).send({ error: error });
    }
  });

  app.get("/wasapp/status", (req, res) => {
    res.send("not implemented :D");
  });

  app.post("/wasapp/disconnect", (req, res) => {
    res.send("not implemented :D");
  });

  const listenUrl = await app.listen({
    port: cfg.port,
    host: "0.0.0.0",
  });
  console.log(`👂 listening on: ${listenUrl}`);

  await whatsappService.initializeSavedClients();
}

main();
