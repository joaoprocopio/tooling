---
title: Run identically in any environment
impact: HIGH
tags: [environments, config, secrets]
---

The suite receives URLs and credentials, and nothing else. No test contains an `if` per environment: the same code runs against staging, QA, or production, changing only environment variables (`E2E_WEB_URL`, `E2E_API_URL`, `E2E_ADMIN_EMAIL`, `E2E_ADMIN_PASSWORD`, …).

The API gets its own URL because it rarely shares the front end’s host, and the provisioning layer builds a request context from it, as described in [provision-via-intent-helpers](provision-via-intent-helpers.md).

Secrets live in a local file outside version control, with a committed example file documenting every required key, or in the CI vault. Never in code.

**Incorrect:**

```ts
if (process.env.TARGET === "staging") {
  await page.goto("https://staging.example.com/admin");
} else {
  await page.goto("https://example.com/admin");
}
```

**Correct:**

```ts
// playwright.config.ts
use: { baseURL: requiredEnv("E2E_WEB_URL") },
// test
await page.goto("/admin");
```

One named exception: choosing a reporter or trace level through `process.env.CI` varies the tooling, not the test behavior, and is acceptable.

Pointing the suite at **production** requires three prerequisites, with no exceptions:

1. Every created record is identifiable by the `E2E-` prefix and covered by automated cleanup.
2. Real side effects such as emails, notifications, and charges are neutralized through dedicated test accounts and data.
3. Cleanup runs at the end of every run, including failed runs.
