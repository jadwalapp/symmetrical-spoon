import fastify, { type RouteShorthandOptions } from "fastify";
import {
  WhatsappService,
  type ClientDetails,
} from "./src/services/whatsapp/whatsapp_service";
import mongoose from "mongoose";
import { getConfig } from "./src/config/config";

async function main() {
  const cfg = getConfig();

  const mongooseConn = await mongoose.connect(cfg.mongodb.uri, {
    dbName: cfg.mongodb.database,
  });

  const app = fastify({
    logger: {
      level: "info",
      transport: {
        target: "pino-pretty",
        options: {
          translateTime: "HH:MM:ss Z",
          ignore: "pid,hostname",
        },
      },
    },
  });

  const whatsappService = new WhatsappService(
    mongooseConn,
    app.log,
    cfg.isHeadless
  );

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
      if (!pairingCode) {
        throw new Error("Failed to get pairing code");
      }

      res.send({ pairingCode: pairingCode });
    } catch (error) {
      console.log(`we got this error: ${error}`);
      req.log.error(
        { error: JSON.stringify(error) },
        "Failed to initialize WhatsApp client"
      );
      res.status(500).send({
        error:
          error instanceof Error ? error.message : "Unknown error occurred",
      });
    }
  });

  const wasappStatusOpts: RouteShorthandOptions = {
    schema: {
      params: {
        type: "object",
        properties: {
          customerId: { type: "string" },
        },
      },
    },
  };
  app.get("/wasapp/status/:customerId", wasappStatusOpts, (req, res) => {
    const { customerId } = req.params as { customerId: string };

    const clientDetails = whatsappService.getClientDetails(customerId);
    if (!clientDetails) {
      res.status(404).send();
      return;
    }

    res.send({
      client: {
        status: clientDetails.status,
        phoneNumber: clientDetails.phoneNumber,
        name: clientDetails.name,
        pairingCode: clientDetails.pairingCode,
        isReady: clientDetails.status === "READY",
        isAuthenticated: ["AUTHENTICATED", "READY"].includes(
          clientDetails.status
        ),
      },
      timestamp: new Date().toISOString(),
    });
  });

  const wasappDisconnectOpts: RouteShorthandOptions = {
    schema: {
      body: {
        type: "object",
        properties: {
          customerId: { type: "string" },
        },
        required: ["customerId"],
      },
      response: {
        500: {
          type: "object",
          properties: {
            error: { type: "string" },
          },
        },
      },
    },
  };
  app.post("/wasapp/disconnect", wasappDisconnectOpts, async (req, res) => {
    try {
      const { customerId } = req.body as { customerId: string };

      await whatsappService.disconnectClient(customerId);

      res.status(200);
    } catch (error) {
      req.log.error({ error }, "Failed to disconnect WhatsApp client");
      res.status(500).send({ error: error });
    }
  });

  const listenUrl = await app.listen({
    port: cfg.port,
    host: "0.0.0.0",
  });
  app.log.info(`👂 listening on: ${listenUrl}`);

  await whatsappService.initializeSavedClients();
}

main();
