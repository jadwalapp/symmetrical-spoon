export interface WasappConfig {
  port: number;
  isHeadless: boolean;
  puppeteerExecuablePath?: string;
  rabbitmq: {
    hostname: string;
    port: number;
    username?: string;
    password?: string;
  };
  wasappMessagesQueueName: string;
}

export function getConfig(): WasappConfig {
  const envStuff = process.env;

  return {
    port: parseInt(envStuff.PORT || "3000"),
    isHeadless: envStuff.IS_HEADLESS === "true",
    puppeteerExecuablePath: envStuff.PUPPETEER_EXECUTABLE_PATH,
    rabbitmq: {
      hostname: envStuff.RABBITMQ_HOSTNAME || "localhost",
      port: parseInt(envStuff.RABBITMQ_PORT || "5672"),
      username: envStuff.RABBITMQ_USERNAME,
      password: envStuff.RABBITMQ_PASSWORD,
    },
    wasappMessagesQueueName:
      envStuff.WASAPP_MESSAGES_QUEUE_NAME || "wasapp.messages",
  };
}
