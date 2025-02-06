export interface WasappConfig {
  port: number;
  isHeadless: boolean;
  puppeteerExecuablePath?: string;
}

export function getConfig(): WasappConfig {
  const envStuff = process.env;

  return {
    port: parseInt(envStuff.PORT || "3000"),
    isHeadless: envStuff.IS_HEADLESS === "true",
    puppeteerExecuablePath: envStuff.PUPPETEER_EXECUTABLE_PATH,
  };
}
