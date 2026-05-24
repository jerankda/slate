import { makeWorker } from "./_shared.js";

export const runSoccerWorker = makeWorker({
  sportSlug: "soccer",
  buildUserPrompt: ({ from, to }) => `Return the upcoming top-tier SOCCER matches between ${from} and ${to}.

Leagues to include (only these): Bundesliga, Premier League, La Liga, Serie A, Ligue 1,
UEFA Champions League, UEFA Europa League.

JSON shape:
{
  "events": [
    {
      "title": "Home vs Away",
      "subtitle": "Matchday 12 (optional)",
      "league": "Bundesliga",
      "start_time_utc": "2026-05-25T18:30:00Z",
      "venue": "Allianz Arena, München",
      "broadcasts": [
        { "provider": "Sky Sport",  "country": "DE", "kind": "tv" },
        { "provider": "DAZN",       "country": "DE", "kind": "stream" },
        { "provider": "Peacock",    "country": "US", "kind": "stream" },
        { "provider": "TNT Sports", "country": "GB", "kind": "tv" }
      ]
    }
  ]
}

- "country" ∈ "DE","US","GB". "kind" ∈ "tv","stream","ppv".
- Every event needs ≥1 broadcaster.
- Aim for the 20–40 most notable matches in window. Quality over quantity.`,
});
