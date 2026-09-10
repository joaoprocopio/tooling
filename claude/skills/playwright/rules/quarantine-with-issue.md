---
title: Quarantine tests only with a linked issue
impact: MEDIUM
tags: [quarantine, hygiene, process]
---

A broken test leaves the suite by fix or by removal, never by being forgotten. Both `test.fixme()` and `test.skip()` require an annotation with an issue link. A skip condition points at matrix dimensions such as engine or persona, never at environment, which would break the run-anywhere contract.

**Incorrect:**

```ts
test.skip("guest confirms attendance", async ({ page }) => {
  /* … */
});
test.skip(process.env.TARGET === "staging", "broken on staging");
```

**Correct:**

```ts
test.fixme(
  "guest confirms attendance",
  {
    annotation: {
      type: "issue",
      description: "https://issues.example.com/E2E-123",
    },
  },
  async ({ page }) => {
    /* … */
  },
);

test.skip(
  ({ browserName }) => browserName === "firefox",
  "no touch events in Firefox",
);
```

Setting `forbidOnly: !!process.env.CI` blocks a forgotten `test.only` from silently shrinking the suite to one test.

Audit the quarantine list every cycle, because quarantine without a deadline is removal in disguise. Fowler’s ceiling works as a default: 8 quarantined tests, or one week to fix or delete.
