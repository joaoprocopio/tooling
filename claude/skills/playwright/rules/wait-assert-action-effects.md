---
title: Assert the effect of every meaningful action
impact: CRITICAL
tags: [waiting, hydration, race-conditions]
---

Playwright’s auto-wait verifies visibility, stability, and occlusion, never the existence of an event handler. In server-side rendered (SSR) apps a button looks ready before JavaScript attaches its listeners, and the docs admit that “Playwright will do its job, but the click won’t have any effect”. The click before hydration is lost **without any error**.

The runner cannot prove the app reacted, so your assertion must. Follow every meaningful action with a web-first assertion of its effect. That turns a hydration race into a local, diagnosable failure instead of a mysterious one three steps later.

**Incorrect** (the lost click fails far from the cause):

```ts
await page.getByTestId("guest-form-submit").click();
await page.getByTestId("next-step-button").click(); // fails here, cause was above
```

**Correct** (the race fails at the action that lost it):

```ts
await page.getByTestId("guest-form-submit").click();
await expect(page.getByTestId("confirmation-banner")).toBeVisible();
```

Four related traps, all documented upstream:

- **“It works if I add a delay” is a diagnosis, not a fix.** The delay that appears to fix a lost click proves the race exists. The real fix belongs in the product, where controls are born `disabled` until hydration completes, or in asserting a deterministic readiness signal.
- **Lazy content shifts layout between aim and click**: Playwright clicks a valid neighbor, with no error. Assert the state that stabilizes the page first (skeleton gone, list loaded) and treat layout shift as a product bug.
- **Popups and downloads**: register `waitForEvent` _before_ the action that triggers it. Registered after the click, the event is lost with no way to recover it. Downloaded files are discarded when the browser context closes, so persist them with `download.saveAs()` inside the test.
- **Dialog listeners**: with no listener Playwright dismisses dialogs on its own, but registering one, even only for logging, transfers that responsibility. Without `accept()` or `dismiss()` the action blocks until timeout.
