// Retains every processed event — unbounded memory growth under load.
const events = [];
let i = 0;

while (true) {
  events.push({ id: i++, payload: 'x'.repeat(1024) });
  if (i % 1000 === 0) {
    const heapMb = Math.round(process.memoryUsage().heapUsed / 1048576);
    console.log(`processed ${i} events, heap ${heapMb}MB`);
  }
}
