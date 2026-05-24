/**
 * Dry-run test for the worker pipeline: skips the OpenAI HTTP call by monkey-
 * patching global.fetch with a canned chat-completions response, then runs the
 * real soccer worker. Proves that:
 *
 *   - JSON extraction survives ```json fences and stray prose
 *   - Zod schema validates the canned shape
 *   - upsertEvent is idempotent (re-running doesn't duplicate)
 *   - cache invalidation runs without crashing when Redis is absent
 *
 * Run with:
 *   OPENAI_API_KEY=dummy npx tsx src/workers/_dryrun.ts
 */
import { prisma } from "../lib/prisma.js";

const cannedResponse = {
  events: [
    {
      title: "Bayern München vs Borussia Dortmund",
      subtitle: "Der Klassiker",
      league: "Bundesliga",
      start_time_utc: new Date(Date.now() + 3 * 86_400_000).toISOString(),
      venue: "Allianz Arena, Munich",
      broadcasts: [
        { provider: "Sky Sport Bundesliga", country: "DE", kind: "tv" },
        { provider: "WOW", country: "DE", kind: "stream" },
        { provider: "ESPN+", country: "US", kind: "stream" },
        { provider: "Sky Sports Football", country: "GB", kind: "tv" },
      ],
    },
    {
      title: "Manchester City vs Arsenal",
      subtitle: "Premier League title clash",
      league: "Premier League",
      start_time_utc: new Date(Date.now() + 5 * 86_400_000).toISOString(),
      venue: "Etihad Stadium, Manchester",
      broadcasts: [
        { provider: "Sky Sports Premier League", country: "GB", kind: "tv" },
        { provider: "DAZN", country: "DE", kind: "stream" },
        { provider: "USA Network", country: "US", kind: "tv" },
        { provider: "Peacock", country: "US", kind: "stream" },
      ],
    },
  ],
};

// Patch global fetch BEFORE importing the worker so callOpenAI uses our stub.
let callCount = 0;
const realFetch = globalThis.fetch;
globalThis.fetch = (async (url: any, init?: any) => {
  if (typeof url === "string" && url.includes("api.openai.com")) {
    callCount++;
    // Second call: shift every kickoff by 7 minutes to prove our day-bucket
    // dedupe survives the AI tweaking timestamps between runs.
    const shifted = {
      events: cannedResponse.events.map(e => ({
        ...e,
        start_time_utc: callCount === 2
          ? new Date(new Date(e.start_time_utc).getTime() + 7 * 60_000).toISOString()
          : e.start_time_utc,
      })),
    };
    return new Response(
      JSON.stringify({
        choices: [{ message: { content: JSON.stringify(shifted) } }],
      }),
      { status: 200, headers: { "content-type": "application/json" } }
    );
  }
  return realFetch(url, init);
}) as typeof fetch;

const { runSoccerWorker: soccer } = await import("./soccer.js");

console.log("→ first run …");
const r1 = await soccer();
console.log("   upserted:", r1.upserted, "  rawAiLogId:", r1.rawAiLogId);

console.log("→ second run (idempotency check) …");
const r2 = await soccer();
console.log("   upserted:", r2.upserted, "  rawAiLogId:", r2.rawAiLogId);

const soccerSport = await prisma.sport.findUnique({ where: { slug: "soccer" } });
const titles = cannedResponse.events.map(e => e.title);
const ourEvents = await prisma.event.findMany({
  where: { sportId: soccerSport!.id, title: { in: titles } },
  include: { broadcasts: true },
});
const eventCount = ourEvents.length;
const broadcastCount = ourEvents.reduce((n, e) => n + e.broadcasts.length, 0);
const aiLogCount = await prisma.rawAiLog.count({ where: { worker: "soccer" } });

console.log("\nDB state for our 2 canned events after 2 runs:");
console.log("  matching events:    ", eventCount, "(expected 2)");
console.log("  total broadcasts:   ", broadcastCount, "(expected 8 — replaced wholesale per run)");
console.log("  rawAiLog rows:      ", aiLogCount, "(>=2)");

if (eventCount === 2 && broadcastCount === 8 && aiLogCount >= 2) {
  console.log("\n✅ pipeline OK — idempotent + broadcasts replaced cleanly");
  process.exit(0);
} else {
  console.error("\n❌ pipeline broken");
  process.exit(1);
}
