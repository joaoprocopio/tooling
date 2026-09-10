---
title: Use web-first assertions and trust auto-waiting
impact: CRITICAL
tags: [waiting, assertions, race-conditions]
---

`await expect(locator)` assertions retry until the condition holds or the timeout expires. They eliminate the race between async rendering and verification, which is the largest single cause of flakiness. Extracting a value and asserting synchronously takes a snapshot and waits for nothing.

**Incorrect** (checks once, waits for nothing, so it flakes):

```ts
expect(await page.getByTestId("welcome-message").isVisible()).toBe(true);
expect(await el.textContent()).toBe("Confirmed");
```

**Correct** (retries until the condition holds):

```ts
await expect(page.getByTestId("welcome-message")).toBeVisible();
await expect(el).toHaveText("Confirmed");
```

An `await` *inside* the parentheses of `expect()` is the smell: it captures a value at an arbitrary instant and loses all polling. Rewrite it as a web-first assertion.

Before every action, Playwright already waits for the element to be visible, stable, enabled, and unobscured. Four consequences follow:

- `page.waitForTimeout()` is either redundant or a mask over a bug. Banned.
- `waitForLoadState("networkidle")` is officially discouraged: it waits for 500 ms with zero network connections, which never happens under polling, WebSockets, or analytics, and happens too early in apps that render after a response. Assert readiness on what the user sees. Banned alongside `waitForTimeout`.
- `force: true` clicks where a real user could not. Fix the obstruction instead. Banned.
- `ElementHandle` (`page.$`, `page.$$`) points at a dead node after a re-render, and the docs themselves discourage the class. Use locators only, because they re-query the DOM on every use.

For conditions outside the DOM, use `expect.poll()` or `expect().toPass()` instead of sleeping.

Enable `@typescript-eslint/no-floating-promises` as an **error**. A forgotten `await` creates a silent race that passes locally and fails in CI, and the lint rule removes that entire bug class at build time.
