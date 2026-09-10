---
title: Keep each journey at the smallest size that proves the behavior
impact: HIGH
tags: [journeys, flakiness, diagnosis]
---

Test by **user journeys**, prioritized by impact of breakage multiplied by frequency of use, and start with the paths whose failure in production causes immediate business damage. Edge cases and form validations belong to the cheaper layers, while E2E covers the main flow and the few high-risk variations.

Then keep each journey as small as its proof allows. Google measured **0.5% flakiness in small tests against 14% in large ones**: every extra step and every extra service is another source of non-determinism, and a journey that proves three things fails for three reasons.

Name the stages with `test.step()`, so the trace reports where the journey broke:

```ts
await test.step("confirms attendance and sees the success message", async () => {
  // …
});
```

Steps are not decoration. Without them a failure arrives as a bare selector error; with them it reads as “broke while confirming attendance”, which is the difference between a stack trace and a diagnosis. What language they are written in is decision 5 in [DECISIONS.md](../DECISIONS.md).
