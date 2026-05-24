import { prisma } from "../lib/prisma.js";

const titles = [
  "Bayern München vs Borussia Dortmund",
  "Manchester City vs Arsenal",
];

await prisma.broadcast.deleteMany({ where: { event: { title: { in: titles } } } });
const r = await prisma.event.deleteMany({ where: { title: { in: titles } } });
console.log("deleted events:", r.count);
const ll = await prisma.rawAiLog.deleteMany({ where: { worker: "soccer" } });
console.log("deleted ai logs:", ll.count);
const remaining = await prisma.event.findMany({ where: { title: { in: titles } } });
console.log("remaining matching events:", remaining.length);
process.exit(0);
