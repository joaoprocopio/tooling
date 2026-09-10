# Decisions each adoption must make

The rules in this skill are non-negotiable. The five choices below are not: they depend on the product, the identity provider (IdP), and the team’s infrastructure. When adopting this skill, decide each one for your project and **record the choice**, in the project’s own docs or config comments. Every contributor re-answers an undecided question differently.

## 1. Authentication: shared `storageState` versus login per test

Two models work, and neither is a safe universal default:

- **`storageState` per persona**: `globalSetup` logs in once per persona, saves the authenticated state to a file outside version control, and every test starts logged in. This costs one login per persona, but every test of that persona shares the state file: if any test mutates account state (settings, profile), determinism breaks under parallelism. Sessions expire, so regenerate the state every run and never reuse the file between runs, because an expired state fails dozens of tests at once and reads as generalized flakiness. Playwright does not capture `sessionStorage`. The login journey itself still needs one dedicated test, since everything else skips it.
- **Login per test (or per worker)**: immune to shared-state mutation, but pays the login cost everywhere and can trip the IdP’s rate limit. Auth0, for example, allows 20 attempts per minute per IP on the same account, which a CI with 8 workers exhausts in seconds, collecting HTTP 429s and lockout.

Four inputs decide it:

- Do tests mutate account state?
- How long do sessions last?
- Does the IdP rate-limit?
- How expensive is one login?

Playwright’s own docs recommend one account per worker (`parallelIndex`) when tests mutate server-side state, which is the evolution path from shared `storageState`.

This decision also covers the credential the **provisioning layer** authenticates with. The suite’s shape does not depend on where that token comes from, because the service layer receives an already-configured request context and never learns its origin. Every adoption still has to answer it: a project with no service token has to log in through the API like any user.

## 2. Where and when the suite runs (CI ladder)

Full continuous integration (CI) from day one is unlikely. Pick the rung you can reach today and climb when the current one is stable:

1. **Disciplined manual**: someone runs the suite against a target environment at defined moments, such as before each release.
2. **Scheduled**: the suite runs daily on a runner or cron, with a published report.
3. **Post-deploy automatic**: the pipeline fires the critical subset (smoke) against the freshly deployed environment, without blocking it.
4. **Deploy gate**: smoke runs before promoting the deploy, and failure blocks promotion. Requires a reliable preview environment and a suite that finishes in minutes.

Record the current rung and the criterion for climbing. When duration bites on the upper rungs, three tools help: sharding with the `blob` reporter plus `merge-reports`, `maxFailures` to abort systemically broken runs, and `--only-changed` as a pull request first stage, never as a substitute for the full run.

## 3. Coverage review with product and stakeholders

Coverage has gaps engineering cannot see alone, and a periodic ritual closes them. Present the journey catalog, from `npx playwright test --list` or the HTML report, which stakeholders can read because the titles are in their language. Then ask: “what, if it broke tomorrow, would make you lose sleep, and is not on this list?” Each answer is a candidate journey. Cadence and format are the project’s call; the loop is what must exist.

## 4. Whether the suite carries the journey numbers, and where

The matrix from `playwright-matrix` numbers every journey, and the suite has to answer which spec covers which row. Two models work:

- **The number lives in the spec file name**, as in `0001-guest-confirms-attendance.spec.ts`. The catalog is then the directory listing, and `npx playwright test --list` or the HTML report generates the readable view on demand. Auditing drift is one command against the matrix’s `tested` rows.
- **The suite carries no number.** The pairing lives in the matrix alone, which is enough for a team that reads the matrix and not the repo, and costs a manual pass to find what a row actually covers.

Whichever you take, numbers are append-only: a new journey takes the next one, and a retired journey keeps its number rather than freeing it for reuse, so old reports and issues keep pointing at the same thing. A parallel `CATALOG.md` is the model to avoid, for the reason test ids need no tracking document: it diverges from the suite the first time someone renames a spec.

## 5. The language of everything a human reads in the report

`test()` and `describe()` titles, and every `test.step()`, are read by whoever decides coverage. Their language is the product’s call, not the codebase’s: for a Brazilian product whose stakeholders read the report, that is pt-BR, and the HTML report then serves as coverage documentation nobody has to translate.

```ts
test("convidado confirma presença pelo link do convite @guest", async ({
  page,
}) => {
  await test.step("abre o convite recebido", async () => {
    // …
  });
});
```

Code identifiers, meaning helpers, fixtures, test ids, and file names, follow the codebase convention as usual. Record the choice, because a suite written half in each language reads as neither.

This decision is what makes decision 3 possible: the coverage review only works if the catalog is readable without a translator.
