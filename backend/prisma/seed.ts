import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const SPORTS = [
  { slug: "soccer", name: "Soccer", icon: "soccerball" },
  { slug: "boxing", name: "Boxing", icon: "figure.boxing" },
  { slug: "mma",    name: "MMA",    icon: "figure.martial.arts" },
  { slug: "nba",    name: "NBA",    icon: "basketball.fill" },
  { slug: "nfl",    name: "NFL",    icon: "football.fill" },
  { slug: "mlb",    name: "MLB",    icon: "baseball.fill" },
];

const PROVIDERS = [
  "Sky Sport", "DAZN", "DAZN PPV", "ESPN+", "Sky Sports",
  "NBA League Pass", "TNT", "TNT Sports", "Peacock", "CBS", "MLB.TV",
];

async function main() {
  console.log("seed: clearing existing data");
  await prisma.broadcast.deleteMany();
  await prisma.participant.deleteMany();
  await prisma.event.deleteMany();
  await prisma.team.deleteMany();
  await prisma.league.deleteMany();
  await prisma.provider.deleteMany();
  await prisma.sport.deleteMany();

  console.log("seed: sports + providers");
  const sportEntries = await Promise.all(
    SPORTS.map(async s => [s.slug, await prisma.sport.create({ data: s })] as const)
  );
  const sports = Object.fromEntries(sportEntries);

  const providerEntries = await Promise.all(
    PROVIDERS.map(async name => [name, await prisma.provider.create({ data: { name } })] as const)
  );
  const providers = Object.fromEntries(providerEntries);

  const now = Date.now();
  const h = (hours: number) => new Date(now + hours * 3600 * 1000);

  type SeedEvent = {
    sport: string;
    league?: string;
    title: string;
    subtitle?: string;
    start: Date;
    venue?: string;
    broadcasts: { provider: string; country: string; kind: string }[];
  };

  const events: SeedEvent[] = [
    { sport: "soccer", league: "Bundesliga", title: "Bayern München vs Borussia Dortmund", subtitle: "Der Klassiker", start: h(3), venue: "Allianz Arena, München",
      broadcasts: [
        { provider: "Sky Sport", country: "DE", kind: "tv" },
        { provider: "DAZN", country: "DE", kind: "stream" },
        { provider: "ESPN+", country: "US", kind: "stream" },
        { provider: "Sky Sports", country: "GB", kind: "tv" },
      ]},
    { sport: "nba", league: "NBA", title: "Lakers vs Celtics", subtitle: "Rivalry Week", start: h(8), venue: "Crypto.com Arena",
      broadcasts: [
        { provider: "NBA League Pass", country: "DE", kind: "stream" },
        { provider: "NBA League Pass", country: "GB", kind: "stream" },
        { provider: "TNT", country: "US", kind: "tv" },
      ]},
    { sport: "soccer", league: "Premier League", title: "Arsenal vs Manchester City", start: h(26), venue: "Emirates Stadium",
      broadcasts: [
        { provider: "Sky Sports", country: "GB", kind: "tv" },
        { provider: "Peacock", country: "US", kind: "stream" },
        { provider: "Sky Sport", country: "DE", kind: "tv" },
      ]},
    { sport: "boxing", title: "Fury vs Usyk II", subtitle: "Heavyweight Unification", start: h(36), venue: "Kingdom Arena, Riyadh",
      broadcasts: [
        { provider: "DAZN PPV", country: "DE", kind: "ppv" },
        { provider: "DAZN PPV", country: "US", kind: "ppv" },
        { provider: "DAZN PPV", country: "GB", kind: "ppv" },
      ]},
    { sport: "mma", league: "UFC 312", title: "Du Plessis vs Strickland 2", subtitle: "Middleweight Title", start: h(60), venue: "Qudos Bank Arena, Sydney",
      broadcasts: [
        { provider: "TNT Sports", country: "GB", kind: "tv" },
        { provider: "DAZN", country: "DE", kind: "stream" },
        { provider: "ESPN+", country: "US", kind: "ppv" },
      ]},
    { sport: "nfl", league: "NFL", title: "Chiefs vs Eagles", subtitle: "Super Bowl LIX Rematch", start: h(72), venue: "Arrowhead Stadium",
      broadcasts: [
        { provider: "DAZN", country: "DE", kind: "stream" },
        { provider: "DAZN", country: "GB", kind: "stream" },
        { provider: "CBS", country: "US", kind: "tv" },
      ]},
    { sport: "soccer", league: "Champions League", title: "Real Madrid vs PSG", subtitle: "Quarter-final, 1st leg", start: h(96), venue: "Santiago Bernabéu",
      broadcasts: [
        { provider: "DAZN", country: "DE", kind: "stream" },
        { provider: "Peacock", country: "US", kind: "stream" },
        { provider: "TNT Sports", country: "GB", kind: "tv" },
      ]},
    { sport: "mlb", league: "MLB", title: "Yankees vs Dodgers", start: h(120), venue: "Yankee Stadium",
      broadcasts: [
        { provider: "MLB.TV", country: "DE", kind: "stream" },
        { provider: "MLB.TV", country: "US", kind: "stream" },
        { provider: "MLB.TV", country: "GB", kind: "stream" },
      ]},
    { sport: "nba", league: "NBA", title: "Warriors vs Nuggets", start: h(168), venue: "Chase Center",
      broadcasts: [
        { provider: "NBA League Pass", country: "DE", kind: "stream" },
        { provider: "NBA League Pass", country: "US", kind: "stream" },
        { provider: "NBA League Pass", country: "GB", kind: "stream" },
      ]},
    { sport: "soccer", league: "La Liga", title: "Barcelona vs Atlético Madrid", start: h(192), venue: "Camp Nou",
      broadcasts: [
        { provider: "DAZN", country: "DE", kind: "stream" },
        { provider: "ESPN+", country: "US", kind: "stream" },
      ]},
  ];

  console.log(`seed: ${events.length} events`);
  for (const e of events) {
    const sport = sports[e.sport];
    let leagueId: string | undefined;
    if (e.league) {
      const league = await prisma.league.upsert({
        where: { sportId_slug: { sportId: sport.id, slug: e.league.toLowerCase().replace(/\s+/g, "-") } },
        update: {},
        create: { sportId: sport.id, slug: e.league.toLowerCase().replace(/\s+/g, "-"), name: e.league },
      });
      leagueId = league.id;
    }
    await prisma.event.create({
      data: {
        sportId: sport.id,
        leagueId,
        title: e.title,
        subtitle: e.subtitle,
        startTimeUtc: e.start,
        venue: e.venue,
        broadcasts: {
          create: e.broadcasts.map(b => ({
            countryCode: b.country,
            kind: b.kind,
            providerId: providers[b.provider].id,
          })),
        },
      },
    });
  }

  console.log("seed: done");
}

main()
  .catch(e => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
