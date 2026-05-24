# slate. backend

Fastify + Prisma. Serves pre-built JSON to the iOS app. AI ingestion workers come later.

**Dev DB:** SQLite (`backend/dev.db`) — zero dependencies, just `npm run dev`.
**Prod DB:** Postgres (switch `datasource db { provider = "postgresql" }` in `prisma/schema.prisma` and point `DATABASE_URL` at it, then re-run `prisma migrate`).
**Redis** is optional in dev — the cache layer fails open.

## Quick start

```bash
cd backend
npm install
npx prisma migrate dev --name init   # creates dev.db (first time only)
npx tsx prisma/seed.ts                # ~10 demo events
npm run dev                           # http://localhost:3000
```

Then:

```bash
curl http://localhost:3000/health
curl http://localhost:3000/v1/sports
curl "http://localhost:3000/v1/sports/soccer/events?country=DE"
```

## Endpoints (v1)

- `GET /health`
- `GET /v1/sports`
- `GET /v1/countries`
- `GET /v1/sports/:slug/events?country=DE&from=…&to=…`
- `GET /v1/events/:id?country=DE`

Responses are gzipped, ETag'd, and Redis-cached for 5 minutes when Redis is reachable.

## Pointing the iOS app at this

1. Find your Mac's LAN IP: `ipconfig getifaddr en0`
2. In the Settings tab in the app, toggle "Use backend" on and (optionally) edit the API base URL.
3. On the simulator, the default `http://localhost:3000/v1` works directly.

## Switching to Postgres later

```bash
docker compose up -d                # postgres + redis
# in .env:
DATABASE_URL="postgresql://slate:slate@localhost:5432/slate?schema=public"
# in schema.prisma:
provider = "postgresql"
# then re-add enums (EventStatus, BroadcastKind) and:
npx prisma migrate dev --name pg_init
npx tsx prisma/seed.ts
```

## Layout

```
backend/
  src/
    server.ts          – Fastify bootstrap + plugins
    routes/
      sports.ts        – /sports, /countries, /sports/:slug/events
      events.ts        – /events/:id
    lib/
      prisma.ts        – Prisma client singleton
      cache.ts         – Redis wrapper (graceful fallback)
    workers/           – future: per-sport AI ingestion workers
  prisma/
    schema.prisma      – data model from plan §5
    seed.ts            – ~10 demo events across the 6 sports
  docker-compose.yml   – Postgres 16 + Redis 7 (for when you outgrow SQLite)
```

## Next phases (per plan)

- **Phase 2: ✅ Soccer worker scaffolded.** Set `OPENAI_API_KEY` in `.env`, then `npm run worker:soccer` to ingest the next 14 days of top-tier matches. Falls back to clean errors with no key.
- Phase 3: workers for boxing, mma, nba, nfl, mlb (drop new file in `src/workers/`, register in `run.ts`)
- Phase 5 (v1.1): APNs push (v1 = local notifications only)

## Workers

```bash
# requires OPENAI_API_KEY in .env
npm run worker:soccer
# generic
npm run worker -- <sport>
```

Each worker:
1. Builds a sport-specific prompt asking OpenAI for strict-JSON events in the next 14 days
2. Logs the raw response to `RawAiLog` for debugging
3. Validates with a Zod schema
4. Upserts events + replaces broadcasts wholesale
5. Invalidates the Redis cache for that sport

The shared harness lives in `src/workers/_shared.ts` (OpenAI call, JSON extraction, upsert helpers).

## Scheduling workers (macOS launchd)

A ready-to-use launchd plist lives at `scripts/com.slate.workers.plist`. It runs `npm run worker:all` every 6 hours and once at login.

```bash
cp scripts/com.slate.workers.plist ~/Library/LaunchAgents/
# Edit WORKING_DIR and OPENAI_API_KEY in the copied file
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.slate.workers.plist
launchctl kickstart -k gui/$(id -u)/com.slate.workers   # run once now
tail -f /tmp/slate-workers.out /tmp/slate-workers.err
```

To remove: `launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.slate.workers.plist`
