import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";
import { cacheGet, cacheSet } from "../lib/cache.js";

const COUNTRIES = [
  { code: "DE", name: "Germany",        flag: "🇩🇪" },
  { code: "US", name: "United States",  flag: "🇺🇸" },
  { code: "GB", name: "United Kingdom", flag: "🇬🇧" },
];

export async function registerSportsRoutes(app: FastifyInstance) {
  app.get("/sports", async () => {
    const cached = await cacheGet("sports");
    if (cached) return cached;
    const sports = await prisma.sport.findMany({
      orderBy: { name: "asc" },
      select: { id: true, slug: true, name: true, icon: true },
    });
    await cacheSet("sports", sports, 600);
    return sports;
  });

  app.get("/countries", async () => COUNTRIES);

  const query = z.object({
    country: z.string().length(2).default("DE"),
    from: z.string().datetime().optional(),
    to: z.string().datetime().optional(),
  });

  // Single endpoint that returns ALL upcoming events across every sport.
  // The iOS Upcoming tab uses this so it only makes one round-trip on load.
  app.get("/events", async (req, reply) => {
    const parsed = query.safeParse(req.query);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.message });
    const { country, from, to } = parsed.data;
    const fromDate = from ? new Date(from) : new Date();
    const toDate   = to   ? new Date(to)   : new Date(Date.now() + 14 * 86400_000);

    const cacheKey = `events:all:${country}:${fromDate.toISOString()}:${toDate.toISOString()}`;
    const cached = await cacheGet(cacheKey);
    if (cached) return cached;

    const events = await prisma.event.findMany({
      where: { startTimeUtc: { gte: fromDate, lte: toDate } },
      orderBy: { startTimeUtc: "asc" },
      include: {
        sport: true,
        league: true,
        broadcasts: { where: { countryCode: country }, include: { provider: true } },
      },
    });

    const payload = events.map(e => ({
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
    }));

    await cacheSet(cacheKey, payload, 300);
    return payload;
  });

  app.get<{ Params: { slug: string } }>("/sports/:slug/events", async (req, reply) => {
    const parsed = query.safeParse(req.query);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.message });
    const { country, from, to } = parsed.data;
    const fromDate = from ? new Date(from) : new Date();
    const toDate   = to   ? new Date(to)   : new Date(Date.now() + 14 * 86400_000);

    const cacheKey = `events:${req.params.slug}:${country}:${fromDate.toISOString()}:${toDate.toISOString()}`;
    const cached = await cacheGet(cacheKey);
    if (cached) return cached;

    const sport = await prisma.sport.findUnique({ where: { slug: req.params.slug } });
    if (!sport) return reply.code(404).send({ error: "Unknown sport" });

    const events = await prisma.event.findMany({
      where: {
        sportId: sport.id,
        startTimeUtc: { gte: fromDate, lte: toDate },
      },
      orderBy: { startTimeUtc: "asc" },
      include: {
        league: true,
        broadcasts: { where: { countryCode: country }, include: { provider: true } },
      },
    });

    const payload = events.map(e => ({
      id: e.id,
      sport_slug: sport.slug,
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
    }));

    await cacheSet(cacheKey, payload, 300);
    return payload;
  });
}
