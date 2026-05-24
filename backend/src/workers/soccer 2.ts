import { z } from "zod";
import { BaseEventSchema, callOpenAI, extractJSON, logAi, upsertEvent } from "./_shared.js";
import { cacheInvalidate } from "../lib/cache.js";

const PayloadSchema = z.object({
  events: z.array(BaseEventSchema),
});

const SYSTEM_PROMPT = `You are a sports schedule research assistant for the "slate." app.
You return STRICT JSON only. No prose, no markdown. Output must match the requested schema.
Only include real, scheduled events. If you are unsure, omit the event rather than guess.
All times must be UTC ISO-8601 with a "Z" suffix. Use today's most-accurate broadcaster
information you have for Germany (DE), the United States (US), and the United Kingdom (GB).`;

function buildUserPrompt(today: Date): string {
  const from = today.toISOString().slice(0, 10);
  const toDate = new Date(today.getTime() + 14 * 86_400_000);
  const to = toDate.toISOString().slice(0, 10);

  return `Return the upcoming top-tier SOCCER matches between ${from} and ${to} (inclusive).

Leagues to include (only these): Bundesliga, Premier League, La Liga, Serie A, Ligue 1,
UEFA Champions League, UEFA Europa League.

Respond with this exact JSON shape:

{
  "events": [
    {
      "title": "Home Team vs Away Team",
      "subtitle": "Matchday 12 — optional, can be null",
      "league": "Bundesliga",
      "start_time_utc": "2026-05-25T18:30:00Z",
      "venue": "Allianz Arena, München",
      "broadcasts": [
        { "provider": "Sky Sport", "country": "DE", "kind": "tv" },
        { "provider": "DAZN",      "country": "DE", "kind": "stream" },
        { "provider": "Peacock",   "country": "US", "kind": "stream" },
        { "provider": "TNT Sports","country": "GB", "kind": "tv" }
      ]
    }
  ]
}

Constraints:
- "country" must be one of: "DE", "US", "GB".
- "kind" must be one of: "tv", "stream", "ppv".
- Every event MUST list at least one broadcaster.
- Aim for the 20–40 most notable matches in that window. Quality over quantity.`;
}

export async function runSoccerWorker(): Promise<{
  upserted: number;
  rawAiLogId: string;
}> {
  const userPrompt = buildUserPrompt(new Date());
  const raw = await callOpenAI({
    systemPrompt: SYSTEM_PROMPT,
    userPrompt,
  });

  const rawAiLogId = await logAi({
    worker: "soccer",
    prompt: userPrompt,
    response: raw,
  });

  const parsed = PayloadSchema.parse(extractJSON(raw));

  let upserted = 0;
  for (const evt of parsed.events) {
    try {
      await upsertEvent({ sportSlug: "soccer", rawAiLogId, event: evt });
      upserted++;
    } catch (e) {
      console.error(`[soccer] failed to upsert "${evt.title}":`, e);
    }
  }

  await cacheInvalidate("sports:soccer:");
  await cacheInvalidate("event:");

  return { upserted, rawAiLogId };
}
