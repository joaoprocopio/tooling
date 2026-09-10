---
title: Treat retry as a detector, not a crutch
impact: CRITICAL
tags: [config, retries, flakiness]
---

Configure `retries: 2` with `failOnFlakyTests: true` in every environment. The retry does not exist to hide failure. It exists to **classify** it:

- Fails all three attempts → a regression.
- Fails then passes → a flake. The run **still fails**, but the report names the right category and attaches evidence from both executions.

```ts
export default defineConfig({
  retries: 2,
  failOnFlakyTests: true,
  use: { trace: "retain-on-failure" },
});
```

Use `trace: "retain-on-failure"`, which records the trace of every attempt and discards the green ones. The official docs recommend `on-first-retry` for cost, but in that mode the trace captured in a flaky scenario comes from the attempt that *passed*. Under `failOnFlakyTests`, the evidence that matters is the first failed attempt, and `retain-on-failure` is the mode that preserves it.

Three published incidents show what this defends:

- Google (2016): 84% of green→red transitions involved a flaky test. Teams learned to dismiss legitimate failures as “probably a flake”, and broken code reached production. That is the scenario `failOnFlakyTests` prevents.
- Shopify: tests individually 99.95% reliable produced a pipeline that passed 35% of the time, because suite reliability is the *product* of individual reliabilities. Flakiness compounds, and surfacing every pass-on-retry is the countermeasure.
- GitHub: 1 in 11 commits had a red build from a flake, and hitting rebuild became a team reflex. The cataloged causes were randomness, time assumptions, and execution-order coupling through shared state.

“Passes locally, breaks in CI” names a race, not a CI defect: the fast, idle local machine masks what runner contention reveals. Reproduce it with `--repeat-each=100 --workers=10` before blaming infrastructure.
