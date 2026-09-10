---
title: Provision test data through intent helpers backed by the API
impact: HIGH
tags: [test-data, setup, api]
---

Every test builds its own world before acting. Build that world through **intent helpers**, functions named for what the test means and provisioned via API underneath, and open the UI only for the behavior under test. Playwright’s own API-testing docs describe this pattern: setup runs in seconds, and failures point at the right place.

Setup through the UI costs three ways. Every test pays browser cost for its own setup, a bug in a base journey cascades into every test that uses it as setup, and every extra minute of UI adds another chance to flake.

**Incorrect** (setup through the UI):

```ts
test("guest confirms attendance", async ({ page }) => {
  await page.goto("/events/new");
  await page.getByTestId("event-name").fill(name);
  // ...12 more UI steps to reach an event with a guest...
});
```

**Correct** (the UI appears only where the behavior is):

```ts
test("guest confirms attendance", async ({ page, api }, testInfo) => {
  const { inviteUrl } = await createEventWithGuest(api, { guestName: uid(testInfo) });
  await page.goto(inviteUrl);
  await page.getByTestId("confirm-attendance").click();
  await expect(page.getByTestId("confirmation-banner")).toBeVisible();
});
```

Three rules govern the layer. They name **roles**, not folders: where the files live is the adopting project’s call.

- **The test never speaks HTTP.** A **service** speaks it; a **helper** says what the test means. Naming the two roles is what makes “tests never call the raw API” a claim a reader can check, instead of a verbal agreement.
- **Helpers express intent**, such as `createEventWithGuests` or `provisionConfirmScenario`, never endpoints.
- **A helper receives its service; it never imports one.** The fixture is the only place the two are wired, so pointing the suite at another backend is a change in one file.

```ts
// the service: speaks HTTP, and knows nothing about why it was called
export class RsvpApi {
  constructor(private request: APIRequestContext) {}
  createEvent(body: NewEvent) { return this.request.post("events/", { data: body }); }
}

// the helper: says what the test means, and receives the service
export const createEventWithGuest = (api: RsvpApi, data: GuestData) => { /* ... */ };
```

## The request context for provisioning

The API rarely shares the front end’s host or headers, which makes the built-in `request` fixture the wrong one: it inherits `baseURL` and `extraHTTPHeaders` from the config, and those belong to the web app. Build a dedicated context instead, logging in once per worker and disposing the context when the test ends:

```ts
export const test = base.extend<{ api: RsvpApi }, { token: string }>({
  token: [async ({ playwright }, use) => {
    await use(await obtainToken(playwright, credentials()));
  }, { scope: "worker" }],

  api: async ({ playwright, token }, use) => {
    const context = await playwright.request.newContext({
      baseURL: requiredEnv("E2E_API_URL"),
      extraHTTPHeaders: { Authorization: `Bearer ${token}` },
    });
    await use(new RsvpApi(context));
    await context.dispose();
  },
});
```

Five constraints hold that fixture together:

- **`page.request` and `context.request` are banned for provisioning.** They read the browser’s cookie jar *and write to it*: a setup call answering with `Set-Cookie` rewrites the session mid-test, and the test then passes or fails on whether the backend happened to renew it. Use `playwright.request.newContext()`, which has an isolated jar. The `playwright` fixture is worker-scoped, since `PlaywrightWorkerArgs` is `{ playwright, browser }`, which is what lets a worker-scoped fixture build one.
- **One login per worker, as long as the token outlives the run.** With 200 tests on 8 workers that is 8 logins instead of 200, and a token is read-only, so sharing it carries none of the mutation hazard a shared `storageState` does. If the token expires before a worker finishes, dozens of tests fail at once with HTTP 401 and it reads as generalized flakiness. At that point the scope drops back to per test, or refresh is added.
- **What crosses to the browser is the token, not the storage state.** The official docs show `apiRequestContext.storageState()` as the bridge, and it carries only what the backend set with `Set-Cookie`. Where the front end writes the session from JavaScript, that state comes back empty. A session-cookie backend is the one case where passing `storageState` is right.
- **`obtainToken` receives its credentials.** One account for the whole suite holds as long as nothing mutates the account itself, and every test already builds its own data, as described in [data-unique-identifiable](data-unique-identifiable.md). One account per worker, keyed by `workerInfo.parallelIndex`, becomes the target the moment tests start changing profile or settings. Because the credentials are injected, that is a change in the fixture and nowhere else.
- **The API must be reachable in every target environment, under its own URL.** That belongs to the environment contract in [env-parametrize-only](env-parametrize-only.md), not to any single test.

Where the credential itself comes from is not this rule’s call: it continues decision 1 in [DECISIONS.md](../DECISIONS.md). How this fixture combines with the ones other rules extend is in [fixtures-compose-explicitly](fixtures-compose-explicitly.md).

The API layer also enables **post-condition checks**: act through the UI, then verify the effect with a GET. That catches an optimistic interface reporting a save the backend never persisted.
