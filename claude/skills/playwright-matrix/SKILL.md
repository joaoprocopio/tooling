---
name: playwright-matrix
description: Discover an application’s user journeys from its code and produce a prioritized E2E test matrix, the ordered plan of what to test first, scored by impact of breakage times frequency of use. Use when planning E2E coverage, deciding which end-to-end test to write next, bootstrapping a Playwright suite for an app that has none, or when the user asks “what should we test”, “map the journeys”, or “build a test matrix”.
---

# E2E test matrix

Produce the **matrix**: a committed, prioritized inventory of the application’s user journeys, ordered by _impact of breakage × frequency of use_. The matrix is the plan that feeds an end-to-end (E2E) suite, and its top untested row is always the next test to write. Invoke the `/playwright` skill to write the tests; this skill decides **what** to test and **in which order**.

One stance is inviolable: **journeys are discovered, never invented.** Every journey in the matrix must trace back to concrete evidence in the code, such as a route, a form, a mutation, or a screen. A journey you cannot point at is fiction, and fiction in a coverage plan is worse than a gap, because it marks ground as covered that nobody ever tested.

## Step 1: build the denominator from code

The denominator is the complete inventory of ways a user reaches the application, and it comes from the code rather than from intuition:

- **Routes**: the router’s route table, meaning every path, including redirects, catch-alls, and auth-gated segments. Beware indirection, because paths hide behind constants such as `ROUTER_PATHS`, or behind dynamic registration. A grep for the literal path returning zero does not mean the route does not exist, so follow the constants.
- **Entry points beyond the router**: deep links sent by email or notification (invite tokens, magic links), embedded and iframe surfaces, and the split between public and authenticated.
- **Mutations**: every form submit and state-changing action reachable from those routes, which is where breakage costs the most.

Completion criterion: **every route accounted for**, each one either mapped to a journey in Step 3 or explicitly excluded with a reason. Record the count as `N routes total: X mapped, Y excluded`, because the denominator is what separates a measured surface from a guessed one. A matrix with a suspiciously round number of areas, each holding about the same number of rows, reveals per-unit budgeting instead of measured surface, and the route count is the antidote.

Directory names are not inventory. A folder listing tells you how engineers organized files, not how users reach behavior. Use it as a hint, never as the denominator.

## Step 2: see what the code does not say

Code tells you what exists; it does not tell you what matters. Fill that in from the sources available, in order of reliability:

1. **Analytics and telemetry**, when reachable: real frequency data beats every estimate.
2. **The user or product team**: ask which flows are revenue-critical, which personas dominate, and what broke before and hurt.
3. **A browser walk** through the running app, when a URL is available: it reveals what the route table cannot, such as which screens are dead ends, what the landing flow funnels into, and what a persona sees first.

When frequency or impact is estimated rather than measured, mark it as an estimate in the matrix. An estimate presented as a measurement corrupts the ordering silently.

## Step 3: group evidence into journeys

A **journey** is a user goal that crosses one or more routes, such as “guest confirms attendance through the invite link” or “operator imports the guest list”. Group the denominator into journeys, each row citing the routes and mutations it covers by `file:line` or route path. Keep each journey at the smallest size that proves one goal, because a journey that needs “and then… and also…” is two journeys.

Assign each journey four attributes:

- **Persona**, with the tag the suite will route it by: `@guest`, `@admin`, and so on
- **Impact of breakage** (high, medium, or low): what the business loses while this is down. Money and irrecoverable moments, such as an event happening _today_, outrank convenience
- **Frequency of use** (high, medium, or low): how often real users walk it, measured when possible, and marked as an estimate otherwise
- **Priority**: impact × frequency, breaking ties toward impact

## Step 4: emit the matrix

Write `e2e/MATRIX.md` in the target repo. It is committed, because it carries what spec file names cannot: priority, what is _not yet_ tested, and what was excluded and why. Use this exact structure:

```markdown
# E2E Test Matrix

Denominator: 34 routes, 31 mapped into journeys, 3 excluded (below).
Frequency source: analytics, product interview, or estimated. Generated: 2026-08-17.

| #    | Journey                                | Persona | Routes         | Impact | Frequency | Priority | Status   |
| ---- | -------------------------------------- | ------- | -------------- | ------ | --------- | -------- | -------- |
| 0001 | journey title, in stakeholder language | @guest  | /invite/:token | high   | high      | P1       | untested |

## Excluded routes

| Route   | Reason                                    |
| ------- | ----------------------------------------- |
| /health | infrastructure endpoint, no user behavior |
```

Numbers are candidates for the suite’s catalog. Whether the suite carries them, and where, is decision 4 of the `/playwright` skill. They are append-only, and when a spec is written its row flips to `tested: 0001-guest-confirms-attendance.spec.ts`. Titles are written in the stakeholders’ language, so the matrix doubles as the coverage conversation with product.

The matrix is the plan; the spec files are the fact. One command audits the drift between them: `npx playwright test --list`, compared against the `tested` rows.

## Step 5: hand off

Close by stating the denominator counts, the top 3 untested journeys, and which one is the next test to write. If the run left estimates where measurements were possible but unreachable, such as no analytics access or an unavailable product team, list them as open items. An unmarked estimate is the only failure mode of this skill that survives review.
