---
title: Generate unique, identifiable, unpredictable test data
impact: HIGH
tags: [test-data, isolation, parallelism]
---

Every piece of data a test creates carries the `E2E-` prefix, which marks it as synthetic suite data and makes it findable with one search. Never reuse fixed data such as “test guest” across tests: shared data is a hidden dependency. Missing isolation is the most common cause of non-deterministic failure, because state left by one test contaminates the next, the failure moves with execution order, and the failing test is rarely the one carrying the bug.

Compose each identifier from two parts: traceable context from `TestInfo`, and a cryptographically random numeric sequence that guarantees uniqueness across parallel tests and simultaneous runs.

```ts
import type { TestInfo } from "@playwright/test";
import { webcrypto } from "node:crypto";

const crypto = globalThis.crypto ?? webcrypto;

function randomDigits(count: number): string {
  const bytes = new Uint8Array(count);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => String(b % 10)).join("");
}

export function uid(testInfo: TestInfo): string {
  const trace = [
    "e2e",
    testInfo.project.name,
    testInfo.testId,
    testInfo.retry,
    randomDigits(8),
  ];

  return trace.join("-");
}
```

Four `TestInfo` fields earn their place in that identifier:

- **`testId`**: stable hash of file plus title, which links an orphan record back to the test that created it
- **`project.name`**: distinguishes the same test running across the device matrix
- **`retry`**: distinguishes attempts
- **`title`**: use it when the data has to stay readable to a human

Two worker-lifecycle traps follow:

- For per-worker resources such as an account pool, key by `parallelIndex` rather than `workerIndex`, because `workerIndex` changes when a worker restarts after a failure.
- Avoid expensive provisioning in `beforeAll`: Playwright replaces the worker after any failure, the hook re-runs on the new worker, and every retry pays the cost again.

Time is shared state too. Assumptions about “today”, days of the month, or daylight saving time produce suites that fail only near midnight or on specific dates. Pin `timezoneId` and `locale` in the config, and `TZ` in the runner process.
