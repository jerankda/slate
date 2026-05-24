import { z } from "zod";
import { prisma } from "../lib/prisma.js";

/**
 * Shared Zod shapes used by every sport worker. Sport-specific workers may
 * extend `BaseEventSchema` with extra fields if they need to.
 */
export const BroadcastSchema = z.object({
  provider: z.string().min(1),
  country: z.enum(["DE", "US", "GB"]),
  kind: z.enum(["tv", "stream", "ppv"]),
});

export const BaseEventSchema = z.object({
  title: z.string().min(3),
  subtitle: z.string().nullable().optional(),
  league: z.string().nullable().optional(),
  start_time_utc: z.string().datetime(),
  venue: z.string().nullable().optional(),
  broadcasts: z.array(BroadcastSchema).min(1),
});

export type BroadcastInput = z.infer<typeof BroadcastSchema>;
export type EventInput = z.infer<typeof BaseEventSchema>;

/**
 * Calls the OpenAI Responses API and returns the raw text. Uses fetch directly
 * so we don't depend on the SDK churn. Asks for strict JSON output.
 */
export async function callOpenAI(opts: {
  systemPrompt: string;
  userPrompt: string;
  model?: string;
}): Promise<string> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) throw new Error("OPENAI_API_KEY is not set");

  const model = opts.model ?? process.env.OPENAI_MODEL ?? "gpt-4o-mini";

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      response_format: { type: "json_object" },
      temperature: 0.2,
      messages: [
        { role: "system", content: opts.systemPrompt },
        { role: "user", content: opts.userPrompt },
      ],
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`OpenAI ${res.status}: ${body.slice(0, 500)}`);
  }
  const data = (await res.json()) as {
    choices: { message: { content: string } }[];
  };
  return data.choices[0]?.message?.content ?? "";
}

/**
 * Records the raw prompt+response so we can debug AI drift after the fact.
 */
export async function logAi(opts: {
  worker: string;
  prompt: string;
  response: string;
}): Promise<string> {
  const row = await prisma.rawAiLog.create({
    data: { worker: opts.worker, prompt: opts.prompt, response: opts.response },
  });
  return row.id;
}

/**
 * Upserts a parsed event + its broadcasts. Idempotent on
 * (sportId, title, startTimeUtc). Returns the event id.
 */
export async function upsertEvent(opts: {
  sportSlug: string;
  rawAiLogId: string | null;
  event: EventInput;
}): Promise<string> {
  const sport = await prisma.sport.findUnique({ where: { slug: opts.sportSlug } });
  if (!sport) throw new Error(`Unknown sport slug: ${opts.sportSlug}`);

  let leagueId: string | null = null;
  if (opts.event.league) {
    const league = await prisma.league.upsert({
      where: { sportId_slug: { sportId: sport.id, slug: slugify(opts.event.league) } },
      update: { name: opts.event.league },
      create: { sportId: sport.id, slug: slugify(opts.event.league), name: opts.event.league },
    });
    leagueId = league.id;
  }

  const startTime = new Date(opts.event.start_time_utc);

  // Find-or-create on (sportId, title, startTimeUtc) — no unique index on those
  // three together so we do this manually to keep the schema flexible.
  const existing = await prisma.event.findFirst({
    where: {
      sportId: sport.id,
      title: opts.event.title,
      startTimeUtc: startTime,
    },
  });

  const event = existing
    ? await prisma.event.update({
        where: { id: existing.id },
        data: {
          subtitle: opts.event.subtitle ?? null,
          venue: opts.event.venue ?? null,
          leagueId,
          rawAiLogId: opts.rawAiLogId,
        },
      })
    : await prisma.event.create({
        data: {
          sportId: sport.id,
          leagueId,
          title: opts.event.title,
          subtitle: opts.event.subtitle ?? null,
          venue: opts.event.venue ?? null,
          startTimeUtc: startTime,
          status: "scheduled",
          rawAiLogId: opts.rawAiLogId,
        },
      });

  // Replace broadcasts wholesale — the AI is the source of truth per run.
  await prisma.broadcast.deleteMany({ where: { eventId: event.id } });
  for (const b of opts.event.broadcasts) {
    const provider = await prisma.provider.upsert({
      where: { name: b.provider },
      update: {},
      create: { name: b.provider },
    });
    await prisma.broadcast.create({
      data: {
        eventId: event.id,
        countryCode: b.country,
        providerId: provider.id,
        kind: b.kind,
      },
    });
  }

  return event.id;
}

function slugify(s: string): string {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

/**
 * Strict JSON parser that tolerates models occasionally wrapping output in
 * ```json fences or stray prose.
 */
export function extractJSON(raw: string): unknown {
  const trimmed = raw.trim();
  // strip fenced code blocks
  const fence = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const body = fence?.[1]?.trim() ?? trimmed;
  // find first { … last } if the body has leading prose
  const first = body.indexOf("{");
  const last = body.lastIndexOf("}");
  if (first === -1 || last === -1) {
    throw new Error("No JSON object found in model output");
  }
  return JSON.parse(body.slice(first, last + 1));
}

/**
 * Tiny factory that turns a sport-specific prompt into a runnable worker.
 * Each sport file just provides its slug, schedule window, and prompt body.
 */
import { z as _z } from "zod";
import { cacheInvalidate } from "../lib/cache.js";

const _PayloadSchema = _z.object({ events: _z.array(BaseEventSchema) });

export function makeWorker(opts: {
  sportSlug: string;
  systemPrompt?: string;
  buildUserPrompt: (range: { from: string; to: string }) => string;
  windowDays?: number;
}) {
  const sys =
    opts.systemPrompt ??
    `You are a sports schedule research assistant for the "slate." app.
Return STRICT JSON only — no prose, no markdown. Output must match the requested schema.
Only include real, scheduled events. If unsure, omit rather than guess.
All times must be UTC ISO-8601 with a "Z" suffix. Use today's most accurate broadcaster
info for Germany (DE), the United States (US), and the United Kingdom (GB).`;

  return async function run(): Promise<{ upserted: number; rawAiLogId: string }> {
    const today = new Date();
    const from = today.toISOString().slice(0, 10);
    const to = new Date(today.getTime() + (opts.windowDays ?? 14) * 86_400_000)
      .toISOString()
      .slice(0, 10);
    const userPrompt = opts.buildUserPrompt({ from, to });

    const raw = await callOpenAI({ systemPrompt: sys, userPrompt });
    const rawAiLogId = await logAi({
      worker: opts.sportSlug,
      prompt: userPrompt,
      response: raw,
    });

    const parsed = _PayloadSchema.parse(extractJSON(raw));

    let upserted = 0;
    for (const evt of parsed.events) {
      try {
        await upsertEvent({ sportSlug: opts.sportSlug, rawAiLogId, event: evt });
        upserted++;
      } catch (e) {
        console.error(`[${opts.sportSlug}] upsert failed for "${evt.title}":`, e);
      }
    }

    await cacheInvalidate(`sports:${opts.sportSlug}:`);
    await cacheInvalidate("event:");

    return { upserted, rawAiLogId };
  };
}
