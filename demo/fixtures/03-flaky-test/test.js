// Simulates a real-world race: the test polls for an event that arrives
// with random latency, using a fixed deadline instead of proper waiting.
const EVENT_DELAY_MS = Math.floor(Math.random() * 20);
const TEST_DEADLINE_MS = 10;

let eventReceived = false;

setTimeout(() => {
  eventReceived = true;
}, EVENT_DELAY_MS);

setTimeout(() => {
  if (!eventReceived) {
    console.error(
      'failure: event not received before deadline ' +
        `(${TEST_DEADLINE_MS}ms), event latency was ${EVENT_DELAY_MS}ms`
    );
    process.exit(1);
  }
  console.log('ok: event received in time');
}, TEST_DEADLINE_MS);
