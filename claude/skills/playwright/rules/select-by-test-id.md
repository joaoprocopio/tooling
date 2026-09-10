---
title: Select elements by test id
impact: HIGH
tags: [selectors, test-ids, contracts]
---

Use `getByTestId()` as the default selector and put the `data-testid` attributes in the application code. Test ids form a contract between the app and the suite, and the suite enforces it by running on every change: removing or renaming a test id breaks the test that depends on it, and the red build is the warning. No parallel tracking document is needed.

This deliberately diverges from the official Playwright guidance, which prioritizes `getByRole()` with an accessible name. Three real incidents drive the divergence:

- Browser auto-translation rewrites DOM text and breaks any text-based selector in a non-English locale.
- Repeated labels on the same screen force positional selection with `nth()`, which breaks when layout changes.
- Copy changes by product decision, not by engineering decision. Slack’s first suite broke on unrelated frontend changes because its selectors were coupled to CSS classes. Moving to dedicated `data-qa` attributes, as one part of a broader UI abstraction, cut flakiness by 60%.

The cost stays explicit: `getByRole` verifies for free that the element is semantically accessible, while `getByTestId` verifies nothing beyond the attribute. Accessibility verification is out of this suite’s scope and belongs to a separate effort.

Three rules complete the selector policy.

Name test ids in kebab-case, scoped by region: `guest-form-submit`, `resume-total-guests`. The region is more than a naming habit, because nested component objects give it structure: each one searches inside its parent’s locator and nowhere else, as described in [structure-component-objects](structure-component-objects.md).

Positional selectors (`.nth()`, `.first()`, `.last()`) are banned, except when order _is_ the behavior under test. To disambiguate list items, filter by the test’s own unique data.

**Incorrect:**

```ts
await page.getByTestId("guest-row").nth(2).click();
```

**Correct:**

```ts
await page
  .getByTestId("guest-row")
  .filter({ hasText: uniqueGuestName })
  .click();
```

Playwright’s strict mode fails when a selector matches two elements. Treat that failure as a warning of an ambiguous contract, not as an obstacle to work around.
