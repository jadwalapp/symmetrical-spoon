export interface WasappConfig {
  port: number;
  mongodb: {
    uri: string;
    database: string;
  };
  isHeadless: boolean;
  puppeteer_execuable_path?: string;
}

export function getConfig(): WasappConfig {
  const envStuff = process.env;

  return {
    port: parseInt(envStuff.PORT || "3000"),
    mongodb: {
      uri: envStuff.MONGODB_URI || "mongodb://localhost:27017",
      database: envStuff.MONGODB_DATABASE || "wasapp",
    },
    isHeadless: envStuff.IS_HEADLESS === "true",
    puppeteer_execuable_path: envStuff.PUPPETEER_EXECUTABLE_PATH,
  };
}
