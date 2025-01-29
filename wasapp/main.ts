import Fastify, { type RouteShorthandOptions } from "fastify";
import { getConfig } from "./src/config/config";
import { WhatsappService } from "./src/services/whatsapp/whatsapp_service";
import { MongoStore } from "wwebjs-mongo";
import mongoose from "mongoose";

async function main() {
  const config = getConfig();
  const app = Fastify({
    logger: true,
    requestTimeout: 30000, // 30 seconds is more reasonable
  });

  const mongooseConn = await mongoose.connect(config.mongodb.uri, {
    dbName: config.mongodb.database,
  });

  const mongoStore = new MongoStore({ mongoose: mongooseConn });
  const whatsappService = new WhatsappService(mongooseConn, app.log);
  await whatsappService.initializeService();

  app.get("/", function (request, reply) {
    reply.send({ hello: "world" });
  });

  interface WhatsappInitializeBody {
    customerId: string;
    phoneNumber: string;
  }

  const whatsappInitializeOpts: RouteShorthandOptions = {
    schema: {
      body: {
        type: "object",
        properties: {
          customerId: { type: "string" },
          phoneNumber: { type: "string" },
        } as const satisfies Record<
          keyof WhatsappInitializeBody,
          { type: "string" }
        >,
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

  app.post(
    "/whatsapp/initialize",
    whatsappInitializeOpts,
    async (request, reply) => {
      const { customerId, phoneNumber } =
        request.body as WhatsappInitializeBody;

      try {
        const pairingCode = await whatsappService.initializeClient(
          customerId,
          phoneNumber
        );
        if (pairingCode === null) {
          return reply.status(500).send({
            error: "Failed to initialize WhatsApp client",
          });
        }

        return reply.send({ pairingCode });
      } catch (error) {
        request.log.error(error);
        return reply.status(500).send({
          error: "Internal server error",
        });
      }
    }
  );

  const whatsappPairingCodeOpts: RouteShorthandOptions = {
    schema: {
      body: {
        type: "object",
        properties: {
          customerId: { type: "string" },
          phoneNumber: { type: "string" },
        } as const satisfies Record<
          keyof WhatsappInitializeBody,
          { type: "string" }
        >,
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

  app.post(
    "/whatsapp/pairing-code",
    whatsappPairingCodeOpts,
    async (request, reply) => {
      try {
        const { customerId, phoneNumber } =
          request.body as WhatsappInitializeBody;
        const code = await whatsappService.getPairingCode(
          customerId,
          phoneNumber
        );
        if (code === null) {
          return reply.status(400).send({
            error: "Failed to generate pairing code. Please try again later.",
          });
        }

        reply.send({ pairingCode: code }); // Fixed to match schema
      } catch (error) {
        request.log.error(error);
        return reply.status(500).send({
          error: "Internal server error",
        });
      }
    }
  );

  const statusOpts: RouteShorthandOptions = {
    schema: {
      querystring: {
        type: "object",
        properties: {
          customerId: { type: "string" },
        },
      },
      response: {
        200: {
          type: "object",
          properties: {
            customerId: { type: "string" },
            status: {
              type: "object",
              properties: {
                isReady: { type: "boolean" },
                isAuthenticated: { type: "boolean" },
                phoneNumber: { type: "string" },
                lastSeen: { type: "string" },
              },
            },
            clients: {
              type: "object",
              additionalProperties: {
                type: "object",
                properties: {
                  isReady: { type: "boolean" },
                  isAuthenticated: { type: "boolean" },
                  phoneNumber: { type: "string" },
                  lastSeen: { type: "string" },
                },
              },
            },
          },
        },
      },
    },
  };

  app.get("/whatsapp/status", statusOpts, async function (request, reply) {
    try {
      const { customerId } = request.query as { customerId?: string };

      if (customerId) {
        const status = await whatsappService.getClientStatus(customerId);
        return reply.send({
          customerId,
          status,
        });
      }

      const statuses = await whatsappService.getAllClientsStatus();
      return reply.send({ clients: statuses });
    } catch (error) {
      request.log.error(error);
      return reply.status(500).send({
        error: "Internal server error",
      });
    }
  });

  const disconnectOpts: RouteShorthandOptions = {
    schema: {
      body: {
        type: "object",
        properties: {
          customerId: { type: "string" },
        },
        required: ["customerId"],
      },
      response: {
        200: {
          type: "object",
          properties: {
            message: { type: "string" },
          },
        },
        404: {
          type: "object",
          properties: {
            error: { type: "string" },
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

  app.post(
    "/whatsapp/disconnect",
    disconnectOpts,
    async function (request, reply) {
      try {
        const { customerId } = request.body as { customerId: string };
        const success = await whatsappService.disconnectClient(customerId);

        if (success) {
          return reply.send({ message: "Client disconnected successfully" });
        } else {
          return reply.status(404).send({
            error: "Client not found or already disconnected",
          });
        }
      } catch (error) {
        request.log.error(error);
        return reply.status(500).send({
          error: "Internal server error",
        });
      }
    }
  );

  try {
    await app.listen({ port: config.port, host: "0.0.0.0" });
    console.log(`Server is running on port ${config.port}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
