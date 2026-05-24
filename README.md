# slate.

> Native iOS app showing what's on, when, and where to watch — across soccer, boxing, MMA, NBA, NFL, and MLB.

Editorial design, zero accounts, zero ads, zero noise. The user never sees that AI is involved — workers ingest schedules from the web into a tiny backend, the phone just reads the result.

<p align="center"><b>slate.</b></p>

## Stack

| Layer        | Tech                                                                 |
| ------------ | -------------------------------------------------------------------- |
| iOS app      | SwiftUI · iOS 26 · `@Observable` · disk-cached, offline-friendly     |
| Backend      | Fastify · Prisma · SQLite (default) or Postgres · optional Redis     |
| Ingestion    | Per-sport TypeScript workers calling the OpenAI Chat API             |
| Scheduling   | `launchd` plist — runs `worker:all` every 6 hours on your Mac        |

## Repo layout

```
slate./           ← Xcode project (SwiftUI app)
backend/          ← Fastify API + Prisma + AI workers
plan.md           ← Product spec and phased delivery roadmap
```

## Quick start

### Backend

```bash
cd backend
cp .env.example .env          # set OPENAI_API_KEY for workers
npm install
npx prisma migrate dev --name init
npm run seed                  # demo events so the iOS app shows something
npm run dev                   # http://localhost:3000
```

Endpoints:

- `GET /v1/sports`
- `GET /v1/countries`
- `GET /v1/sports/:slug/events?country=DE`
- `GET /v1/events?country=DE` — aggregate used by the iOS home screen
- `GET /v1/events/:id`

### iOS

Open `slate./slate..xcodeproj` in Xcode 26+ and run on an iPhone simulator.
The app falls back to bundled demo data if the backend is unreachable. Settings → Data source lets you toggle backend mode and set the base URL.

### Workers

```bash
cd backend
npm run worker:soccer   # or boxing / mma / nba / nfl / mlb
npm run worker:all      # run every sport
```

Schedule them every 6 hours via the included launchd plist — see `backend/README.md`.

## Design principles

- **Editorial, not dashboard.** Big type, lots of whitespace, restrained motion.
- **One job per screen.** Up Next is the home, everything else is a sub-task.
- **The phone never talks to OpenAI.** All AI work lives server-side.
- **No accounts. No ads. No purple gradients.**

Full design system in [`plan.md`](./plan.md) §12.

## Phased delivery

| Phase | Status | Notes                                                       |
| ----- | ------ | ----------------------------------------------------------- |
| 0 — Foundations               | ✅ | App + backend scaffolds, design tokens                 |
| 1 — End-to-end vertical slice | ✅ | Backend → iOS over HTTP with mock fallback             |
| 2 — Real ingestion            | ✅ | Soccer AI worker with shared harness                   |
| 3 — All sports                | ✅ | 6 workers via `makeWorker` factory + aggregate route   |
| 4 — Polish                    | ✅ | Offline cache, skeletons, LIVE pill, 3-state status    |
| 5 — Notifications             | ✅ | Local reminders with lead-time picker + manage screen  |
| 6 — TestFlight                | 🚧 | App icon, launch screen, version bump, store listing   |

## License

Private. © Daniel Jeranko (brekzware).
