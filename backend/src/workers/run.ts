import { runSoccerWorker } from "./soccer.js";
import { runBoxingWorker } from "./boxing.js";
import { runMmaWorker } from "./mma.js";
import { runNbaWorker } from "./nba.js";
import { runNflWorker } from "./nfl.js";
import { runMlbWorker } from "./mlb.js";
import { prisma } from "../lib/prisma.js";

type WorkerFn = () => Promise<{ upserted: number; rawAiLogId: string }>;

const WORKERS: Record<string, WorkerFn> = {
  soccer: runSoccerWorker,
  boxing: runBoxingWorker,
  mma:    runMmaWorker,
  nba:    runNbaWorker,
  nfl:    runNflWorker,
  mlb:    runMlbWorker,
};

async function main() {
  const slug = process.argv[2];
  if (!slug || (slug !== "all" && !WORKERS[slug])) {
    console.error(`Usage: tsx src/workers/run.ts <sport|all>`);
    console.error(`Available: ${Object.keys(WORKERS).join(", ")}, all`);
    process.exit(1);
  }

  const slugs = slug === "all" ? Object.keys(WORKERS) : [slug];
  let totalUpserted = 0;
  let failures = 0;

  for (const s of slugs) {
    console.log(`[${s}] starting…`);
    const t0 = Date.now();
    try {
      const { upserted, rawAiLogId } = await WORKERS[s]();
      totalUpserted += upserted;
      const ms = Date.now() - t0;
      console.log(`[${s}] upserted ${upserted} events in ${ms}ms (rawAiLogId=${rawAiLogId})`);
    } catch (e) {
      failures++;
      console.error(`[${s}] failed:`, e);
    }
  }

  if (slugs.length > 1) {
    console.log(`\n[all] total upserted: ${totalUpserted}, failures: ${failures}/${slugs.length}`);
  }
  if (failures > 0) process.exitCode = 1;
  await prisma.$disconnect();
}

main();
