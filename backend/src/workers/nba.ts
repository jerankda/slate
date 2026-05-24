import { makeWorker } from "./_shared.js";

export const runNbaWorker = makeWorker({
  sportSlug: "nba",
  buildUserPrompt: ({ from, to }) => `Return upcoming NBA games between ${from} and ${to}.

If we're in the regular season: limit to ~20 most notable matchups (rivalries, top teams,
star players, nationally televised slots).
If we're in the playoffs/finals: include every playoff game in window.

JSON shape:
{
  "events": [
    {
      "title": "Boston Celtics vs Los Angeles Lakers",
      "subtitle": null,
      "league": "NBA",
      "start_time_utc": "2026-05-26T00:00:00Z",
      "venue": "TD Garden, Boston",
      "broadcasts": [
        { "provider": "NBA League Pass", "country": "DE", "kind": "stream" },
        { "provider": "NBA League Pass", "country": "GB", "kind": "stream" },
        { "provider": "TNT",             "country": "US", "kind": "tv" },
        { "provider": "ESPN",            "country": "US", "kind": "tv" }
      ]
    }
  ]
}

- "country" ∈ "DE","US","GB". "kind" ∈ "tv","stream","ppv".
- NBA League Pass covers DE+GB+US streaming for most games.
- Nationally televised US games: TNT, ESPN, ABC, NBA TV.`,
});
