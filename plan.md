# slate. — iOS App Plan

> **Name:** `slate.` — always lowercase, always with the trailing period. It's the wordmark.
> **Launch countries:** Germany, United States, United Kingdom.
> **Pricing:** Free, no IAP in v1.
> **Apple Developer account:** ✅ active.
> **Push notifications:** deferred to v1.1. v1 uses **local notifications only**.
> **Logo:** Placeholder wordmark (`slate.` set in SF Pro Rounded Black, ink color, accent-green period) until commissioned.



## 1. Product in one sentence
A native iOS app that shows users upcoming sports events (soccer, boxing, MMA, NBA, NFL, MLB) with start times, participants, and where to watch them (TV channel / streaming service) in their country.

## 2. Core principle
The user-facing app is **read-only and fast**. It only fetches pre-built JSON from our backend.
AI is **never** called from the phone. AI is a backend ingestion worker that discovers events on a schedule and writes normalized rows to a database.

```
[Cron workers] -> [OpenAI / official APIs] -> [Normalize + validate]
       -> [Postgres] -> [Redis cache] -> [REST API] -> [iOS app]
```

## 3. Scope for v1 (MVP)
Ship the smallest thing that proves the concept.

**In scope:**
- 6 sports: soccer (top 5 EU leagues + Champions League), boxing, MMA (UFC), NBA, NFL, MLB
- Country selector (start with: DE, US, UK)
- List of upcoming events (next 14 days) per sport
- Event detail screen: teams/fighters, start time in user's local timezone, broadcasters for selected country
- Pull-to-refresh, basic offline cache
- Push notifications: "Event starts in 1 hour" (opt-in, per event)

**Out of scope for v1:**
- Live scores
- User accounts / login
- Favourites sync across devices
- Apple Watch
- iPad-optimized layout (works but not polished)
- Android

## 4. Tech stack

### iOS app
- **Swift 5.10 + SwiftUI** (iOS 17+)
- **Async/await** for networking, `URLSession` directly (no Alamofire)
- **SwiftData** for local cache of events (so app opens instantly offline)
- **UserNotifications** for local + push notifications
- **Xcode 16**, single target, no CocoaPods. Use SPM only.

### Backend
- **Node.js 20 + TypeScript**
- **Fastify** for the HTTP API (lightweight, fast)
- **Prisma** ORM + **PostgreSQL 16**
- **Redis** for response caching + worker queue
- **BullMQ** for scheduled ingestion jobs
- **Zod** for strict schema validation of AI output
- **OpenAI Node SDK** (gpt-4o or whatever is current/cheapest)

### Infra (cheap, dead simple)
- **Backend + DB:** Railway or Fly.io (one project, Postgres + Redis add-ons)
- **Push notifications:** APNs directly (no Firebase needed for iOS-only)
- **Monitoring:** Logtail / Axiom for logs, UptimeRobot for ping
- **Domain + TLS:** Cloudflare in front

Total expected monthly cost early on: **< €30**.

## 5. Data model (Postgres via Prisma)

```
sports        (id, slug, name, icon)
leagues       (id, sport_id, slug, name, country)
teams         (id, league_id, name, short_name, logo_url)
events        (id, sport_id, league_id, home_team_id, away_team_id,
               title, start_time_utc, status, venue, raw_ai_id)
participants  (id, event_id, name, role)   -- for boxing/MMA where there are no "teams"
broadcasts    (id, event_id, country_code, provider_id, kind)  -- kind = tv | stream | ppv
providers     (id, name, logo_url, website)
raw_ai_log    (id, worker, prompt, response, created_at)  -- keep raw output for debugging
```

Key rules:
- All times stored as UTC. iOS converts to local.
- `events` are deduped on (sport_id, start_time_utc, home_team_id, away_team_id) or (sport_id, title, start_time_utc) for combat sports.
- Every normalized row links back to its `raw_ai_log` row so we can debug hallucinations.

## 6. Ingestion pipeline (backend)

One worker file **per sport**. No mega-prompt.

```
backend/src/workers/
  soccer.ts
  boxing.ts
  mma.ts
  nba.ts
  nfl.ts
  mlb.ts
```

Each worker:
1. Runs on a schedule (BullMQ repeatable job).
2. Sends a sport-specific prompt to OpenAI asking for upcoming events in **strict JSON**.
3. Stores the raw response in `raw_ai_log`.
4. Parses JSON, validates with a sport-specific Zod schema.
5. Normalizes (resolve team names to existing `teams` rows, parse dates to UTC).
6. Upserts into `events` + `broadcasts`.
7. Invalidates Redis cache keys for that sport.

Schedules (initial guess, tune later):
- Soccer: every 6h
- NBA/NFL/MLB: every 12h
- Boxing/MMA: every 24h

Expected OpenAI usage: **20–50 calls/day → a few euros/month**.

Later (v2): replace AI with official APIs for sports that have them (NBA, NFL, MLB, major soccer leagues via API-Football). Keep AI only for boxing, MMA, and "where to watch" enrichment.

## 7. REST API (what the iOS app calls)

Base: `https://api.<domain>/v1`

```
GET /sports
GET /sports/:slug/events?country=DE&from=2026-05-24&to=2026-06-07
GET /events/:id?country=DE
GET /countries           -- supported country codes
```

Rules:
- All responses cached in Redis for 5 minutes.
- All responses gzipped.
- ETag + `If-None-Match` so the iOS app can do cheap revalidation.
- No auth in v1. Add an API key header later if abuse appears.

## 8. iOS app structure

```
MappyGmae/                 (rename later)
  App/
    MappyGmaeApp.swift
    AppEnvironment.swift   -- API base URL, country, etc.
  Features/
    Sports/                -- list of sports (home screen)
    Events/                -- list of events per sport
    EventDetail/           -- single event view
    Settings/              -- country picker, notification prefs
  Core/
    Networking/
      APIClient.swift      -- async URLSession wrapper
      Endpoints.swift
    Models/                -- Codable structs matching API responses
    Cache/
      SwiftDataStack.swift
      EventStore.swift     -- read/write cached events
    Notifications/
      NotificationManager.swift
  Resources/
    Assets.xcassets
    Localizable.strings
```

Navigation: `NavigationStack` per tab. Tab bar: **Sports | Upcoming | Settings**.

## 9. Screens (v1)

1. **Sports tab** — grid of sport cards. Tap → events list filtered to that sport.
2. **Upcoming tab** — flat chronological list of all events across sports for the selected country, next 14 days. Filter chip row at top (All / Soccer / Boxing / …).
3. **Event detail** — title, start time (local), countdown, broadcaster logos for user's country, "Notify me 1h before" toggle.
4. **Settings** — country picker, default sports to show, notification permission prompt, about/credits.

## 10. Phased delivery

**Phase 0 — Foundations (week 1)**
- Init Xcode project (SwiftUI, iOS 17).
- Init backend repo (Fastify + Prisma + Postgres locally via Docker).
- Define Prisma schema from section 5. Run migration.
- Seed a fake `events` table with hand-written JSON so iOS has something to read.

**Phase 1 — End-to-end vertical slice (week 2)**
- Backend: `GET /sports` and `GET /sports/:slug/events` returning seeded data.
- iOS: Sports tab + Events list reading from local backend over LAN.
- No AI, no cache, no notifications yet. Just prove the pipe works.

**Phase 2 — Real ingestion (week 3)**
- Build the soccer worker end-to-end (prompt → Zod → DB).
- Add Redis caching.
- Deploy backend to Railway/Fly. Point iOS at the real URL.

**Phase 3 — All sports (week 4)**
- Copy the soccer worker pattern for boxing, MMA, NBA, NFL, MLB.
- Each sport gets its own prompt + Zod schema.

**Phase 4 — Polish (week 5)**
- Event detail screen with broadcasters.
- Country picker + persistence.
- SwiftData offline cache.
- Pull-to-refresh, empty/error states, loading skeletons.

**Phase 5 — Notifications (week 6)**
- Local notifications only ("notify me 1h before"). No server, no APNs in v1.
- Push notifications deferred to v1.1.

**Phase 6 — TestFlight (week 7)**
- Invite 5–10 testers. Collect feedback. Fix top 5 issues. Submit to App Store.

## 11. Things to deliberately NOT do
- No accounts in v1.
- No Firebase, no Supabase, no GraphQL, no microservices, no Kubernetes.
- No live scores (different problem, needs websockets + real data feed).
- No calling OpenAI from the phone. Ever.
- No "AI chat" feature. The user never sees that AI is involved.

## 12. Design system (non-negotiable)

**Reference bar:** Flighty, Things 3, Bear, Halide, Dark Noise. Apple Design Award energy.
**Zero tolerance for:** purple/pink gradients, "AI shimmer" effects, generic Material Design, sad-face empty states, stock icon sets.

### Color tokens
| Token | Light | Dark | Purpose |
|---|---|---|---|
| `background` | `#FAF8F4` (warm off-white) | `#000000` (true black, OLED) | App background |
| `surface` | `#FFFFFF` | `#0E0E10` | Cards, sheets |
| `surfaceElevated` | `#FFFFFF` + shadow | `#17171A` | Floating elements |
| `ink` | `#0E0E10` | `#F4F2EE` | Primary text |
| `muted` | `#8A8A8E` | `#8A8A8E` | Secondary text |
| `accent` | `#1FB85B` (Pitch Green) | `#1FB85B` | Brand, primary actions |
| `live` | `#FF8A1E` (Floodlight Amber) | `#FF8A1E` | Live/urgent badges only |
| `hairline` | `#0E0E10` @ 8% | `#FFFFFF` @ 10% | Separators |

One accent. One alert. No gradients on chrome. Per-sport accents are monochrome tints of `accent`, not a rainbow.

### Typography
- **Display:** SF Pro Display, weights 700/900. Used for kickoff times, countdowns, sport headers.
- **Body:** SF Pro Text, weights 400/600.
- **Numeric:** monospaced digits (`.monospacedDigit()`) on every time/countdown so they don't jitter.

### Materials & depth
- Nav bars, tab bar, floating "Live" pill, modal sheets: `.ultraThinMaterial`.
- Real glass, not faked with opacity hacks.
- Shadows: soft, large radius, low opacity (`y: 8, blur: 24, opacity: 0.08`). Never harsh.
- Cards: 16pt corner radius, continuous (`RoundedRectangle(cornerRadius: 16, style: .continuous)`).

### Motion
- All transitions use spring physics: `.spring(response: 0.45, dampingFraction: 0.82)`.
- Event card → detail uses `matchedGeometryEffect` for hero animation.
- No linear easing anywhere.
- Reduce Motion respected (fade fallback).

### Haptics (subtle, never spammy)
- `.soft` on tab change, segmented control change.
- `.rigid` on card tap entering detail.
- `.success` when a notification is scheduled.
- `.warning` on failed network refresh.
- Wired through a single `Haptics` enum, not scattered `UIImpactFeedbackGenerator` calls.

### Iconography
- SF Symbols only in v1 (variable weight + hierarchical rendering).
- Custom sport glyphs commissioned later as SF Symbol-compatible SVGs.

### Empty / error / loading states
- Every screen has a custom-designed empty state (illustration TBD, copy is friendly and specific).
- Loading: skeleton shimmer in `surface` tone, never a spinning wheel.
- Errors: inline, with a single clear action ("Try again"). Never an alert dialog.

## 13. Open decisions (still need answers)
- Bundle ID — suggest `com.<yourhandle>.slate`. What's your handle / org?
