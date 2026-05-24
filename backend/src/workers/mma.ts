import { makeWorker } from "./_shared.js";

export const runMmaWorker = makeWorker({
  sportSlug: "mma",
  buildUserPrompt: ({ from, to }) => `Return the upcoming MMA events between ${from} and ${to}.

Focus on UFC: numbered events (e.g. "UFC 312") AND Fight Nights. One row per event,
titled after the main event ("Aldo vs Pantoja" or the official "UFC Fight Night: X vs Y").
Optionally include the biggest Bellator / PFL / ONE Championship cards if they fall in window.

JSON shape:
{
  "events": [
    {
      "title": "Aldo vs Pantoja",
      "subtitle": "UFC 312 — Flyweight Title",
      "league": "UFC",
      "start_time_utc": "2026-06-01T03:00:00Z",
      "venue": "T-Mobile Arena, Las Vegas",
      "broadcasts": [
        { "provider": "DAZN",       "country": "DE", "kind": "stream" },
        { "provider": "ESPN+",      "country": "US", "kind": "ppv" },
        { "provider": "TNT Sports", "country": "GB", "kind": "tv" }
      ]
    }
  ]
}

- "country" ∈ "DE","US","GB". "kind" ∈ "tv","stream","ppv".
- Numbered UFC events are usually PPV in US (ESPN+ PPV) but free on DAZN in DE.
- Typical 2–6 events in a 2-week window.`,
});
