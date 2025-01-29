export interface WasappConfig {
  port: number;
  mongodb: {
    uri: string;
    database: string;
  };
}

export function getConfig(): WasappConfig {
  const envStuff = process.env;

  return {
    port: parseInt(envStuff.PORT || "3000"),
    mongodb: {
      uri: envStuff.MONGODB_URI || "mongodb://localhost:27017",
      database: envStuff.MONGODB_DATABASE || "wasapp",
    },
  };
}
