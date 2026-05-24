import Fastify from "fastify";
import cors from "@fastify/cors";
import compress from "@fastify/compress";
import etag from "@fastify/etag";
import { registerSportsRoutes } from "./routes/sports.js";
import { registerEventRoutes } from "./routes/events.js";

const app = Fastify({
  logger: {
    transport: process.env.NODE_ENV === "production" ? undefined : {
      target: "pino-pretty",
      options: { translateTime: "HH:MM:ss", ignore: "pid,hostname" },
    },
  },
});

await app.register(cors, { origin: true });
await app.register(compress, { global: true });
await app.register(etag);

app.get("/health", async () => ({ status: "ok", time: new Date().toISOString() }));

await app.register(async v1 => {
  await registerSportsRoutes(v1);
  await registerEventRoutes(v1);
}, { prefix: "/v1" });

const port = Number(process.env.PORT ?? 3000);
const host = process.env.HOST ?? "0.0.0.0";

try {
  await app.listen({ port, host });
  app.log.info(`slate. api listening on http://${host}:${port}`);
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
