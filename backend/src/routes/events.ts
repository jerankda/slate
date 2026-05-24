import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";
import { cacheGet, cacheSet } from "../lib/cache.js";

export async function registerEventRoutes(app: FastifyInstance) {
  const query = z.object({ country: z.string().length(2).default("DE") });

  app.get<{ Params: { id: string } }>("/events/:id", async (req, reply) => {
    const parsed = query.safeParse(req.query);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.message });
    const { country } = parsed.data;

    const cacheKey = `event:${req.params.id}:${country}`;
    const cached = await cacheGet(cacheKey);
    if (cached) return cached;

    const e = await prisma.event.findUnique({
      where: { id: req.params.id },
      include: {
        sport: true,
        league: true,
        broadcasts: { where: { countryCode: country }, include: { provider: true } },
      },
    });
    if (!e) return reply.code(404).send({ error: "Event not found" });

    const payload = {
      id: e.id,
      sport_slug: e.sport.slug,
      league: e.league?.name ?? null,
      title: e.title,
      subtitle: e.subtitle,
      start_time_utc: e.startTimeUtc.toISOString(),
      venue: e.venue,
      broadcasts: e.broadcasts.map(b => ({
        provider: b.provider.name,
        country_code: b.countryCode,
        kind: b.kind,
      })),
    };

    await cacheSet(cacheKey, payload, 300);
    return payload;
  });
}
