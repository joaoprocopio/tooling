---
title: Clean up with a janitor at the end of the session
impact: MEDIUM
tags: [cleanup, teardown, hygiene]
---

Test correctness never depends on cleanup: each test creates its own world and ignores leftovers from others. Cleanup is environment hygiene, and it runs as a **janitor** in `globalTeardown`, sweeping every record carrying the `E2E-` prefix at the end of the session. The sweep assumes one run per environment at a time, because simultaneous runs against the same environment sweep each other’s data as they finish.

Three rules complete the design:

- A failed run preserves its data for investigation. Against production, the sweep always runs.
- The same janitor code exists as a standalone script (`npm run e2e:janitor`) to sweep leftovers of runs killed by crash or job timeout, since `globalTeardown` does not run after `kill -9`.
- Individual tests do **not** tear down their data. Per-test teardown skips a crash, deletes the evidence of failures, and adds cost to every test.

**Incorrect** (per-test teardown deletes evidence and skips a crash):

```ts
test.afterEach(async ({ api }) => {
  await api.deleteGuest(guestId);
});
```

**Correct** (session-level sweep by prefix):

```ts
// global-teardown.ts
await api.deleteAllWithPrefix("E2E-");
```

This design accepts one known cost in exchange for fewer moving parts at the start: `globalTeardown` runs outside the report, so a failure there produces no trace and no HTML entry. When the suite grows, migrate the janitor to a teardown project through project dependencies, which gains trace, report, and retry.
