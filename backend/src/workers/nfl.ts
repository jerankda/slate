import { makeWorker } from "./_shared.js";

export const runNflWorker = makeWorker({
  sportSlug: "nfl",
  buildUserPrompt: ({ from, to }) => `Return upcoming NFL games between ${from} and ${to}.

If the regular season / playoffs are running: include every game in window.
If we are in the off-season: return an empty events array.

JSON shape:
{
  "events": [
    {
      "title": "Kansas City Chiefs vs Buffalo Bills",
      "subtitle": "Week 12 — Sunday Night Football",
      "league": "NFL",
      "start_time_utc": "2026-11-23T01:20:00Z",
      "venue": "Arrowhead Stadium, Kansas City",
      "broadcasts": [
        { "provider": "DAZN",    "country": "DE", "kind": "stream" },
        { "provider": "NBC",     "country": "US", "kind": "tv" },
        { "provider": "Peacock", "country": "US", "kind": "stream" },
        { "provider": "DAZN",    "country": "GB", "kind": "stream" }
      ]
    }
  ]
}

- "country" ∈ "DE","US","GB". "kind" ∈ "tv","stream","ppv".
- DAZN holds NFL Game Pass rights in DE+GB.
- US per-game: CBS (AFC), Fox (NFC), NBC (SNF), ESPN/ABC (MNF), Amazon (TNF), Netflix (Christmas).`,
});
