import { makeWorker } from "./_shared.js";

export const runBoxingWorker = makeWorker({
  sportSlug: "boxing",
  buildUserPrompt: ({ from, to }) => `Return the upcoming notable BOXING cards between ${from} and ${to}.

Focus on world-title fights, Top Rank, Matchroom, PBC, Queensberry, Riyadh Season cards.
Include only the main event of each card (one row per card). Use the headline bout as the title,
e.g. "Usyk vs Fury 2".

JSON shape:
{
  "events": [
    {
      "title": "Fighter A vs Fighter B",
      "subtitle": "WBC Heavyweight Title",
      "league": null,
      "start_time_utc": "2026-05-30T22:00:00Z",
      "venue": "Kingdom Arena, Riyadh",
      "broadcasts": [
        { "provider": "DAZN PPV",   "country": "DE", "kind": "ppv" },
        { "provider": "DAZN PPV",   "country": "US", "kind": "ppv" },
        { "provider": "DAZN PPV",   "country": "GB", "kind": "ppv" },
        { "provider": "Sky Sports Box Office", "country": "GB", "kind": "ppv" }
      ]
    }
  ]
}

- "country" ∈ "DE","US","GB". "kind" ∈ "tv","stream","ppv".
- Every card needs ≥1 broadcaster per country it actually airs in.
- Typical 4–10 cards in a 2-week window — quality only.`,
});
