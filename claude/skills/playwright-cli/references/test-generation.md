# Test generation (plan → generate → heal)

End-to-end workflow for authoring and maintaining Playwright tests with `playwright-cli`. Every `playwright-cli` action emits the equivalent Playwright TypeScript, and that generated code is the raw material for every test. Use the four sections below independently:

- **How generation works**: the core mechanic everything else relies on, where actions become TypeScript, plus how to add assertions
- **Plan**: explore the app, and produce a spec file describing what to test
- **Generate**: turn a spec into Playwright test files, updating the spec when it is vague or stale
- **Heal**: diagnose failing tests, fix the code, and reconcile the spec with reality

Plan, generate, and heal all rely on the same mechanic: run `npx playwright test --debug=cli` in the background, then `playwright-cli attach tw-abcdef` to drive the paused page interactively. The debug and attach mechanics are covered in [running and debugging Playwright tests](playwright-tests.md).

## 0. How generation works

Every action you perform with `playwright-cli` generates the corresponding Playwright TypeScript code. That code appears in the output and can be copied straight into your test files.

```bash
# start a session
playwright-cli open https://example.com/login

# take a snapshot to see elements
playwright-cli snapshot
# output shows: e1 [textbox "Email"], e2 [textbox "Password"], e3 [button "Sign In"]

# fill form fields, which generates code automatically
playwright-cli fill e1 "user@example.com"
# Ran Playwright code:
# await page.getByRole('textbox', { name: 'Email' }).fill('user@example.com');

playwright-cli fill e2 "your_password_here"
# Ran Playwright code:
# await page.getByRole('textbox', { name: 'Password' }).fill('your_password_here');

playwright-cli click e3
# Ran Playwright code:
# await page.getByRole('button', { name: 'Sign In' }).click();
```

### Building a test file

Collect the generated code into a Playwright test, then add the assertions by hand:

```typescript
import { test, expect } from "@playwright/test";

test("login flow", async ({ page }) => {
  // generated code from the playwright-cli session
  await page.goto("https://example.com/login");
  await page.getByRole("textbox", { name: "Email" }).fill("user@example.com");
  await page
    .getByRole("textbox", { name: "Password" })
    .fill("your_password_here");
  await page.getByRole("button", { name: "Sign In" }).click();

  // added by hand
  await expect(page).toHaveURL(/.*dashboard/);
});
```

### Use semantic locators

The generated code uses role-based locators where it can, and those survive markup changes that break a CSS selector:

```typescript
// generated, and semantic
await page.getByRole("button", { name: "Submit" }).click();

// fragile, because a CSS selector breaks on restyling
await page.locator("#submit-btn").click();
```

### Explore before recording

Take snapshots to understand the page structure before recording actions:

```bash
playwright-cli open https://example.com
playwright-cli snapshot
# review the element structure
playwright-cli click e5
```

### Add assertions manually

Generated code captures actions but not assertions. Add expectations to your test using one of the recommended matchers:

- **`toBeVisible()`**: the element is rendered and visible
- **`toHaveText(text)`**: the element’s text content matches
- **`toHaveValue(value)` and `toBeEmpty()`**: the input or select value matches
- **`toBeChecked()` and `toBeUnchecked()`**: the checkbox state matches
- **`toMatchAriaSnapshot(snapshot)`**: the page, or a locator, matches a partial accessibility snapshot

Use `playwright-cli generate-locator <target>` to produce the locator expression for the assertion, and the snapshot and eval commands to capture the expected value.

When asserting text content, check that the generated locator does not contain text from the element itself. `getByTestId()` and `getByLabel()` pair well with a text assertion. When the locator is text-based, prefer `toBeVisible()` instead.

An aria snapshot does not have to hold everything on the page: capture only what the assertion needs, and use regular expressions for unstable values.

```bash
# get a stable locator for an element ref to use in the assertion
playwright-cli --raw generate-locator e5
# getByRole('button', { name: 'Submit' })

# capture expected text content for toHaveText
playwright-cli --raw eval "el => el.textContent" e5

# capture expected input value for toHaveValue and toBeEmpty
playwright-cli --raw eval "el => el.value" e5

# capture expected aria snapshot for toMatchAriaSnapshot and toBeChecked,
# for the whole page, or scoped to a region with a ref
playwright-cli --raw snapshot
playwright-cli --raw snapshot e5
```

Those outputs become the assertions:

```typescript
// generated action
await page.getByRole("button", { name: "Submit" }).click();

// manual assertions using the outputs above
await expect(page.getByRole("alert", { name: "Success" })).toBeVisible();
await expect(page.getByTestId("main-header")).toHaveText("Welcome, user");
await expect(page.getByRole("textbox", { name: "Email" })).toHaveValue(
  "user@example.com",
);
await expect(
  page.getByRole("checkbox", { name: "Enable notifications" }),
).toBeChecked();

// toMatchAriaSnapshot on the whole page finds a matching region
await expect(page).toMatchAriaSnapshot(`
  - heading "Welcome, user"
  - link /\\d+ new messages?/
  - button "Sign out"
`);

// toMatchAriaSnapshot scoped to a region
await expect(page.getByRole("navigation")).toMatchAriaSnapshot(`
  - link "Home"
  - link /\\d+ new messages?/
  - link "Profile"
`);
```

## 1. Planning

Goal: produce a spec file, such as `specs/<feature>.plan.md`, enumerating the scenarios to test. **Always** write the spec to a file.

### 1.1 Prerequisite: workspace

Check that the workspace has Playwright installed before anything else:

```bash
# either of these confirms a workspace
test -f playwright.config.ts || test -f playwright.config.js
npx --no-install playwright --version
```

When Playwright is missing, bootstrap it and let the user pick the defaults:

```bash
npm init playwright@latest
```

### 1.2 Prerequisite: seed test

A **seed test** is a minimal test that puts the page in the state every scenario starts from: navigation to the app, any required login, and feature flags. Scenarios assume a fresh start _after_ the seed. Since `--debug=cli` pauses _inside_ this test, the seed is where every planning and generation session begins.

The minimum viable seed navigates and nothing more:

```ts
// tests/seed.spec.ts
import { test } from "@playwright/test";

test("seed", async ({ page }) => {
  await page.goto("https://example.com/");
});
```

Better: push navigation into a fixture, so scenario tests reuse it:

```ts
// tests/fixtures.ts
import { test as baseTest } from "@playwright/test";
export { expect } from "@playwright/test";

export const test = baseTest.extend({
  page: async ({ page }, use) => {
    await page.goto("https://example.com/");
    await use(page);
  },
});
```

```ts
// tests/seed.spec.ts
import { test } from "./fixtures";

test("seed", async ({ page }) => {
  // the fixture already navigates, and this empty body marks where agents start
});
```

When no seed exists, create one that at least navigates to the app.

### 1.3 Explore the app

Launch the app through the seed in the background, then attach:

```bash
PLAYWRIGHT_HTML_OPEN=never npx playwright test tests/seed.spec.ts --debug=cli
# wait for "Debugging Instructions" and the session name tw-abcdef
playwright-cli attach tw-abcdef
```

Resume so the seed runs, then probe the app:

```bash
playwright-cli resume                   # resume so the seed test runs fully
playwright-cli snapshot                 # inventory of interactive elements
playwright-cli click e5                 # follow a flow
playwright-cli eval "location.href"     # read URL and state
playwright-cli show --annotate          # ask the user to point at something
```

Map out five things:

- Interactive surfaces: forms, buttons, lists, filters, modals
- Primary user journeys, end to end
- Edge cases: empty states, validation errors, long input, boundary values
- Persistence: reload, local and session storage, URL fragments
- Navigation: which controls change the URL, and back and forward behavior

**Important**: always reach the app through the test rather than opening its URL with `playwright-cli`, so you capture any custom setup the test performs.

**Important**: stop the background test when you finish exploring.

### 1.4 Write the spec file

Save the spec under `specs/<feature>.plan.md`, using this structure:

```markdown
# Feature name test plan

## Application overview

One paragraph describing what the feature does and why it matters.

## Test scenarios

### 1. Group name

**Seed:** `tests/seed.spec.ts`

#### 1.1. kebab-case-scenario-name

**File:** `tests/<group>/<kebab-case-scenario-name>.spec.ts`

**Steps:**

1. Concrete user step - expect: observable outcome - expect: another observable outcome
2. Next step - expect: outcome
```

Further scenarios in the same group continue as `#### 1.2.`, `#### 1.3.`, and so on. A new group opens its own `### 2.` heading with its own `**Seed:**` line.

Five guidelines govern the spec:

- Each scenario is independent and starts from the seed’s fresh state. Never chain scenarios.
- Scenario names are kebab-case and match the test file name, so `should-add-single-todo` becomes `should-add-single-todo.spec.ts`.
- Cover the happy path, edge cases, validation, negative flows, and persistence.
- Write steps at the user level, such as “Type ‘Buy milk’ into the input”, rather than at the API level, such as “call `fill`”.
- Put observable outcomes in `- expect:` bullets, because each one becomes an assertion during generation.

## 2. Generate

Goal: take a spec file and produce Playwright test files, updating the spec when it has drifted.

### 2.1 Inputs

Generation takes three inputs:

- **Spec file**, such as `specs/basic-operations.plan.md`
- **Target**: a single scenario such as `1.2`, a whole group such as `1`, or all of them
- **Seed file**, read from the `**Seed:**` line of the scenario’s group

### 2.2 Generate one scenario

Handle target scenarios one at a time, never in parallel, because they share the seed session:

```bash
PLAYWRIGHT_HTML_OPEN=never npx playwright test <seed-file> --debug=cli   # background
playwright-cli attach tw-abcdef
# resume
```

Always reach the app through the test rather than opening its URL with `playwright-cli`, so you capture any custom setup the test performs.

Walk the scenario’s `Steps:` one by one with `playwright-cli`, treating the spec as the plan and the live app as the source of truth. A step may be vague (“click the button”, but which button?), reference an element that no longer exists, or contradict the app’s actual behavior. Use your judgment: update the spec to match the app’s observed behavior, then keep going. Editing the spec mid-generation is expected.

Every action prints the equivalent Playwright TypeScript, as described in [How generation works](#0-how-generation-works):

```bash
playwright-cli snapshot                         # find refs
playwright-cli fill e3 "John Doe"               # -> getByRole('textbox').fill(...)
playwright-cli press Enter
playwright-cli click e7
```

For each `- expect:` bullet, add an explicit assertion, following [How generation works](#0-how-generation-works).

Collect the generated code and write the test file at the path the spec gives:

```ts
// spec: specs/basic-operations.plan.md
// seed: tests/seed.spec.ts
// import from '@playwright/test' when the project has no fixtures file
import { test, expect } from "./fixtures";

test.describe("Signing in and out", () => {
  test("should sign in", async ({ page }) => {
    // 1. Navigate to the application
    // (handled by the seed fixture)

    // 2. Type 'John Doe' into the username field
    await page.getByRole("textbox", { name: "username" }).fill("John Doe");

    // 3. Type password
    await page
      .getByRole("textbox", { name: "password" })
      .fill("your_password_here");

    // 4. Press Enter to submit
    await page.getByRole("textbox", { name: "password" }).press("Enter");

    await expect(page.getByRole("heading")).toContainText("Welcome, John Doe!");
  });
});
```

Five rules govern the generated file:

- **One test per file.** File path, describe name, and test name come verbatim from the spec, minus the ordinal.
- Prefix each numbered step with a `// N. <step text>` comment before its actions.
- Use the describe group name verbatim from the spec, without the `1.` ordinal.
- Import from `./fixtures` when the project has one, and from `@playwright/test` otherwise.
- **Important**: close the CLI session and stop the background test before moving to the next scenario.

### 2.3 Generate multiple scenarios

Loop section 2.2 over the targeted scenarios one at a time, restarting the seed between each, so every test starts from a clean page. Confirm each test run is stopped before starting the next.

### 2.4 Run generated tests

After generation, run the new tests once:

```bash
PLAYWRIGHT_HTML_OPEN=never npx playwright test tests/<group>/<scenario>.spec.ts
```

Any failure goes to section 3.

## 3. Heal

Goal: fix failing tests, and update the spec when the app’s intended behavior changed.

### 3.1 Find failing tests

Run the suite and collect the failures:

```bash
PLAYWRIGHT_HTML_OPEN=never npx playwright test
```

Record the list of failing `<file>:<line>` entries and process them one at a time. Shared state and the single CLI session make parallel fixes fragile.

### 3.2 Debug one failure

Run the single failing test in debug mode in the background, then attach:

```bash
PLAYWRIGHT_HTML_OPEN=never npx playwright test tests/<group>/<scenario>.spec.ts:<line> --debug=cli
# wait for "Debugging Instructions" and the tw-abcdef session name
playwright-cli attach tw-abcdef
```

The test is paused at the start. Step forward until immediately before the failing action or assertion, then diagnose:

```bash
playwright-cli snapshot                # did the element change, move, or get renamed?
playwright-cli console                 # app-side errors?
playwright-cli requests                # failed request? wrong payload?
playwright-cli show --annotate         # ask the user to point somewhere
```

Six causes account for most failures: selector drift, a new wrapper element, a label or ARIA rename, timing (a transition or an async load), assertion text updated in the app, and test data leaking between runs.

Rehearse the corrected interaction with `playwright-cli`, because the generated code in the output is what you paste back into the test.

### 3.3 Apply the fix

Edit the test file: update the locator, assertion, step order, or inputs to match the corrected behavior. Stop the background debug run, then rerun the single test to confirm it passes.

Never skip hooks or add sleeps as a fix, and never use `networkidle`.

### 3.4 Reconcile with the spec

Open the spec referenced by the `// spec:` header in the test file, and locate the scenario matching the test. Three cases follow:

- **The fix was purely technical** (locator drift, a better assertion shape) and the spec’s user-level behavior still matches the app → leave the spec alone.
- **The fix changed user-visible steps, inputs, order, or expected outcomes** that the spec describes → update the spec to match reality. Keep the scenario id and file path stable, and change only the step and expect lines.
- **It is unclear whether the app change is intentional** (the spec is stale) **or a regression** (the test was right, the app is wrong) → **stop and ask the user**, providing the scenario id (such as `2.3`), the spec lines that no longer match, and the observed app behavior, quoting a snapshot excerpt or a concrete outcome.

Only after the user answers, either update the spec (intentional change) or flag the test as covering a bug (regression).

### 3.5 Iteration and giving up

Fix failures one at a time, rerunning after each. When investigation leaves you confident that the test is correct and the app is wrong, _and_ the user has confirmed it is a bug, mark the test `test.fixme(...)` with a comment pointing at the user’s decision or the issue link. Never silently skip.

## Cross-references

| For                                                | See                                                           |
| -------------------------------------------------- | ------------------------------------------------------------- |
| `--debug=cli` and attach mechanics                 | [running and debugging Playwright tests](playwright-tests.md) |
| Mocking requests during exploration and generation | [request mocking](request-mocking.md)                         |
| Managing the CLI browser session                   | [browser session management](session-management.md)           |
