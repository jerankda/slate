import Redis from "ioredis";

const url = process.env.REDIS_URL ?? "redis://localhost:6379";
const redisDisabled = process.env.REDIS_DISABLED === "1" || !process.env.REDIS_URL;

export const redis = new Redis(url, {
  lazyConnect: true,
  maxRetriesPerRequest: 1,
  enableOfflineQueue: false,
});

let warnedOnce = false;
redis.on("error", err => {
  if (warnedOnce) return;
  warnedOnce = true;
  console.warn(`redis unavailable (${err.message.split("\n")[0]}); continuing without cache`);
});

let connected = false;
let tried = false;
async function ensure() {
  if (connected || redisDisabled) return;
  if (tried) return;
  tried = true;
  try { await redis.connect(); connected = true; }
  catch { /* offline-tolerant */ }
}

export async function cacheGet<T>(key: string): Promise<T | null> {
  await ensure();
  if (!connected) return null;
  try {
    const v = await redis.get(key);
    return v ? (JSON.parse(v) as T) : null;
  } catch { return null; }
}

export async function cacheSet(key: string, value: unknown, ttlSeconds = 300): Promise<void> {
  await ensure();
  if (!connected) return;
  try { await redis.set(key, JSON.stringify(value), "EX", ttlSeconds); } catch {}
}

export async function cacheInvalidate(prefix: string): Promise<void> {
  await ensure();
  if (!connected) return;
  try {
    const keys = await redis.keys(`${prefix}*`);
    if (keys.length) await redis.del(...keys);
  } catch {}
}
