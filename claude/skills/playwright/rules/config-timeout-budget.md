---
title: Define an explicit timeout budget
impact: MEDIUM
tags: [config, timeouts, diagnosis]
---

Generous default timeouts hide real slowness and worsen diagnosis, because the failure arrives as a generic test timeout instead of naming the slow action. Fix a budget in the config, and handle exceptions case by case with `test.slow()` or a per-call `{ timeout }`, always with a stated justification:

```ts
use: {
  actionTimeout: 15_000,
  navigationTimeout: 30_000,
},
```

The defaults of 30s per test and 5s per `expect` work as a starting point. In CI, add `globalTimeout` to protect the pipeline’s total budget.

**Incorrect** (a slow API surfaces as “Test timeout of 30000ms exceeded” with no culprit):

```ts
// no actionTimeout, so the click absorbs the whole test budget
await page.getByTestId("submit").click();
```

**Correct** (the same failure names the action that blew its share):

```ts
// actionTimeout: 15_000 in config, so the failure reads "click exceeded 15000ms"
await page.getByTestId("submit").click();
```
