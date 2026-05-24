For your use case, I would build this:
                ┌────────────────┐
                │ Cron / Workers │
                └──────┬─────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
   OpenAI Web     Official APIs    Scrapers
      Search         (optional)      (later)
        │
        └──────► Normalization ◄─────┘
                       │
                 JSON validation
                       │
                    PostgreSQL
                       │
                    Redis cache
                       │
                 REST / GraphQL API
                       │
                    Frontend
Tech stack:
Backend:
Node.js
TypeScript
Fastify or NestJS
Prisma ORM
PostgreSQL
Redis
OpenAI API
Frontend:
Next.js
React
Tailwind CSS
Infra:
Vercel for frontend
Railway or Hetzner VPS for backend
Supabase if you want easy Postgres auth/storage
Do NOT overengineer with Kubernetes or microservices. Completely unnecessary.
Your core concept:
You are not serving “AI responses”.
You are serving:
structured sports event data
The AI is only the ingestion worker.
That mindset matters.
Your DB schema should look roughly like:
sports
leagues
teams
events
broadcasts
providers
Example event:
{
  "id": "uuid",
  "sport": "soccer",
  "league": "Premier League",
  "homeTeam": "Arsenal",
  "awayTeam": "Chelsea",
  "startTimeUtc": "2026-05-24T15:00:00Z",
  "status": "scheduled",
  "broadcasts": [
    {
      "country": "DE",
      "provider": "Sky Sports"
    }
  ]
}
Now the actual important part:
the ingestion pipeline.
You should NOT have one generic mega-prompt.
That becomes garbage fast.
Instead:
workers/
  soccer.ts
  boxing.ts
  mma.ts
  nba.ts
  nfl.ts
  mlb.ts
Each sport has:
custom prompts
custom schemas
custom parsing rules
Because sports are structurally different.
Soccer:
leagues
matchdays
simultaneous games
Boxing:
fight cards
undercards
PPV
no seasons
MMA:
event-based
fight cancellations constantly
NBA/NFL:
standings
playoffs
preseason
live scores
Different domains entirely.
Flow for soccer worker:
every 6 hours:
    ask OpenAI:
        "give EPL fixtures next 7 days in strict JSON"

validate response
dedupe events
upsert DB
cache Redis
Flow for boxing worker:
every 12 hours:
    ask:
        "list major upcoming boxing events"

extract:
- main card
- fighters
- titles
- broadcasters
- venue
Now the most important engineering decision:
Use AI for DISCOVERY.
Not for realtime serving.
Bad:
user request -> GPT
Good:
scheduled ingestion -> DB -> user
That is the difference between:
stable app
expensive unstable mess
You should also version your normalized schema.
Example:
type SoccerEventV1 = {}
type BoxingEventV1 = {}
because your data shape WILL evolve.
Another thing:
you should store:
raw AI response
parsed normalized response
Why?
Because when parsing fails later you can debug:
prompt issue
hallucination
formatting drift
Massively useful.
Your ingestion step should look like:
OpenAI response
    ↓
JSON parse
    ↓
Zod validation
    ↓
normalize fields
    ↓
store raw + normalized
Use:
zod
valibot
JSON schema
Mandatory.
Now scaling.
For your categories:
boxing
mma
soccer
basketball
football
baseball
you honestly only need:
maybe 20–50 OpenAI calls/day initially
That’s tiny.
Likely:
under €20/month early on
maybe much less with batching
You can even batch prompts:
Give me:
- today's EPL fixtures
- today's MLB fixtures
- today's NBA fixtures

Return JSON grouped by sport.
But honestly I’d still separate workers for maintainability.
Now the thing you should absolutely add later:
Hybrid sourcing.
Example:
OpenAI for boxing + MMA discovery
official APIs for NBA/NFL/MLB
AI enriches streaming info
Because structured sports APIs are insanely reliable for:
scores
schedules
standings
while AI is better at:
“where to watch”
relevance ranking
summaries
extracting messy information
Long-term ideal architecture:
official APIs = truth
AI = enrichment + aggregation
That’s the mature version of your idea.