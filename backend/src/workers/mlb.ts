import { makeWorker } from "./_shared.js";

export const runMlbWorker = makeWorker({
  sportSlug: "mlb",
  buildUserPrompt: ({ from, to }) => `Return upcoming MLB games between ${from} and ${to}.

Limit to ~20 most notable games in window (rivalries, top teams, nationally televised,
playoffs/World Series if applicable).

JSON shape:
{
  "events": [
    {
      "title": "New York Yankees vs Los Angeles Dodgers",
      "subtitle": null,
      "league": "MLB",
      "start_time_utc": "2026-06-05T23:05:00Z",
      "venue": "Yankee Stadium, Bronx",
      "broadcasts": [
        { "provider": "MLB.TV", "country": "DE", "kind": "stream" },
        { "provider": "MLB.TV", "country": "US", "kind": "stream" },
        { "provider": "MLB.TV", "country": "GB", "kind": "stream" },
        { "provider": "ESPN",   "country": "US", "kind": "tv" }
      ]
    }
  ]
}

- "country" ∈ "DE","US","GB". "kind" ∈ "tv","stream","ppv".
- MLB.TV is the international stream everywhere.
- US national windows: ESPN (Sunday Night), Fox (Saturday), TBS, Apple TV+ (Fridays).`,
});
