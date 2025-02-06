import fastify, { type RouteShorthandOptions } from "fastify";
import { WasappService } from "./src/service";
import mongoose from "mongoose";
import { getConfig } from "./src/config";

async function main() {
  const cfg = getConfig();

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

  const wasappService = new WasappService(
    cfg.isHeadless,
    cfg.puppeteerExecuablePath
  );
  console.log(`before initialize saved clients`);
  await wasappService.initializeSavedClients();
  console.log(`after initialize saved clients`);

  app.get("/health", (_, res) => {
    res.status(200).send("ok");
  });

  // START - Setup graceful shutdown
  const signals = ["SIGTERM", "SIGINT"] as const;
  let shuttingDown = false;

  async function gracefulShutdown(signal: string) {
    if (shuttingDown) return;
    shuttingDown = true;

    console.log(`Received ${signal}. Starting graceful shutdown...`);

    try {
      console.log("Closing HTTP server...");
      await app.close();
      console.log("HTTP server closed");

      console.log("Shutting down WhatsApp service...");
      await wasappService.gracefulShutdown();
      console.log("WhatsApp service shut down");

      console.log("Closing MongoDB connection...");
      await mongoose.disconnect();
      console.log("MongoDB connection closed");

      console.log("Graceful shutdown completed");
      process.exit(0);
    } catch (error) {
      console.error("Error during shutdown:", error);
      process.exit(1);
    }
  }

  signals.forEach((signal) => {
    process.on(signal, () => gracefulShutdown(signal));
  });
  // END - Setup graceful shutdown

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

      console.log("before initialize");

      const pairingCode = await wasappService.initialize(
        customerId,
        phoneNumber
      );
      console.log(`after initialize: ${pairingCode}`);
      if (!pairingCode) {
        console.log("failed to get pairing code");
        throw new Error("Failed to get pairing code");
      }

      console.log("before sending pairing code");

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

    const clientDetails = wasappService.getClientDetails(customerId);
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

      await wasappService.deleteClient(customerId);

      res.status(200).send();
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
}

try {
  main();
} catch (error) {
  console.error(`things went south: ${error}`);
}
