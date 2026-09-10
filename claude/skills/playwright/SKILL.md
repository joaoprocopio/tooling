---
name: playwright
description: Rules for writing deterministic, flake-free end-to-end tests with Playwright. Use when writing, reviewing, or debugging Playwright tests, setting up an E2E config or harness, investigating a flaky test, or choosing selectors, test data, waits, or timeouts. Applies even when the user never says “flaky” or “deterministic”.
---

# Playwright deterministic testing

This skill holds the rules that keep an end-to-end suite trustworthy: four non-negotiable principles, the config that encodes them, and one rule file per area (waiting, selectors, test data, structure, config).

A test is **deterministic** when the same application code always produces the same result: on any machine, in any order, at any parallelism. A test is **flaky** when it alternates between green and red with no change in the code under test. Flakiness is always a bug, either in the test (implicit wait, shared data, ambiguous selector) or in the application (a real race the user also hits).

A suite with flakes loses the only thing that makes it valuable: trust in the signal. Once the team adopts the re-run reflex, the suite stops informing anyone, even while it keeps executing. Every rule here protects that signal.

## Non-negotiable principles

The rest of this skill derives from these four:

1. **Every test is independent and self-contained.** A test creates everything it needs and references only what it created. No test depends on another test, on execution order, or on state left by previous runs.
2. **Every test is deterministic.** Implicit waits (`waitForTimeout`), shared data, and ambiguous selectors are forbidden. A test that needs a retry to pass is broken.
3. **The whole suite runs in parallel.** Set `fullyParallel: true` from day one. Parallelism is not a late optimization: it is the continuous proof that principle 1 holds.
4. **Flakiness fails the run.** With `failOnFlakyTests: true`, a test that failed and passed on retry fails the whole run. A flake is a bug with priority, never tolerated noise.

The minimal config that encodes them:

```ts
export default defineConfig({
  fullyParallel: true,
  retries: 2,
  failOnFlakyTests: true,
  forbidOnly: !!process.env.CI,
  use: {
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
});
```

## Rules

Ordered by impact: the top rules sustain every rule below them. Read the rule file before working on its area.

| Rule | Impact |
| --- | --- |
| [wait-web-first-assertions](rules/wait-web-first-assertions.md) | CRITICAL |
| [wait-assert-action-effects](rules/wait-assert-action-effects.md) | CRITICAL |
| [config-retry-as-detector](rules/config-retry-as-detector.md) | CRITICAL |
| [select-by-test-id](rules/select-by-test-id.md) | HIGH |
| [journeys-smallest-proof](rules/journeys-smallest-proof.md) | HIGH |
| [data-unique-identifiable](rules/data-unique-identifiable.md) | HIGH |
| [provision-via-intent-helpers](rules/provision-via-intent-helpers.md) | HIGH |
| [fixtures-compose-explicitly](rules/fixtures-compose-explicitly.md) | HIGH |
| [env-parametrize-only](rules/env-parametrize-only.md) | HIGH |
| [network-no-mocks](rules/network-no-mocks.md) | HIGH |
| [cleanup-janitor](rules/cleanup-janitor.md) | MEDIUM |
| [wait-disable-animations](rules/wait-disable-animations.md) | MEDIUM |
| [structure-persona-projects](rules/structure-persona-projects.md) | MEDIUM |
| [structure-component-objects](rules/structure-component-objects.md) | MEDIUM |
| [config-timeout-budget](rules/config-timeout-budget.md) | MEDIUM |
| [quarantine-with-issue](rules/quarantine-with-issue.md) | MEDIUM |

## Per-project decisions

Some choices are real tradeoffs that depend on the product, the identity provider, and the team’s infrastructure, so this skill does not decide them for you. When adopting the skill, work through [DECISIONS.md](DECISIONS.md) and record each choice in the project.

## Out of scope

- **Visual regression by screenshot** (`toHaveScreenshot`): pixel baselines require identical rendering environments between generation and verification, which conflicts with running from any machine against any URL, and multiplies baselines across the device matrix. Targeted structural assertions (`toMatchAriaSnapshot`) cover part of the need with far more stability.
- **Accessibility scans**: worth doing, especially because the test-id-first selector choice gives up the semantic verification `getByRole` performs for free. They belong to a separate effort, not to this suite.
