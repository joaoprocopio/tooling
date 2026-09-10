---
title: Wrap shared UI knowledge in component objects
impact: MEDIUM
tags: [structure, components, selectors]
---

Everything a test knows about the interface, meaning a URL, a selector, or an interaction, lives in a **component object** and never in the spec. The unit is the **component**, not the page: a form that appears on five screens is written once, and components nest the way the application’s own components do.

This diverges from the official Page Object Model guidance, which organizes by page. Slack’s suite made the same move, “treating the application as components rather than pages”, and measured a 60% flakiness reduction after migrating. That is the incident already cited in [select-by-test-id](select-by-test-id.md). Organizing by page copies a shared component once per screen that shows it.

The layer also turns _scoped by region_ into structure instead of a naming convention: a nested component receives its parent’s locator and can only see inside it, so an ambiguous test id trips strict mode where it is declared.

A route component takes `Page`, because it navigates, and exposes its children as methods:

```ts
// components/GuestsPage.ts
export class GuestsPage {
  constructor(private page: Page) {}

  root() {
    return this.page.getByTestId("guests-page");
  }
  form() {
    return new GuestForm(this.root());
  }
  table() {
    return new GuestsTable(this.root());
  }

  async open(eventId: string) {
    await this.page.goto(`/${eventId}/guest`);
  }
}
```

A nested component takes the parent’s `Locator`, and every lookup starts from it:

```ts
// components/GuestForm.ts
export class GuestForm {
  constructor(private parent: Locator) {}

  root() {
    return this.parent.getByTestId("guest-form");
  }
  name() {
    return this.root().getByTestId("name");
  }

  async fillName(value: string) {
    await this.name().fill(value);
  }
}
```

The spec then reads as the journey, with no selector in sight:

```ts
// journeys/0001-guest-confirms-attendance.spec.ts
const guests = new GuestsPage(page);
await guests.open(eventId);
await guests.form().fillName("Ana");
await expect(guests.form().root()).toBeVisible();
```

Seven rules govern the layer:

- **A route component takes `Page`; a nested component takes the parent’s `Locator`.** The only difference that matters between the two types is that `Page` navigates and `Locator` does not.
- **The route component owns the URL.** A route change is then fixed in one file, for the same reason the selector moved in here.
- **Every accessor is a method, with no getters and no fields.** The constructor stores its dependency and each accessor computes on call. That costs nothing, because a `Locator` resolves nothing until it is used, and it removes the trap where a class field initializer runs before the constructor body and sees an unassigned root.
- **Element accessors return `Locator`; child accessors return the child component.** Assertions against a child go through its root: `expect(guests.form().root()).toBeVisible()`. Typing `.root()` is the whole price of never maintaining a custom matcher per assertion you want to use.
- **Components act; tests verify.** No `expect` inside a component, because “the UI abstraction is stateless; the test should maintain the state and validate against it”. A component that asserts moves the proof out of the spec, and the spec stops saying what it proves.
- **A component only touches its own section.** It gets its parent’s locator and never reaches outside it.
- **No chaining.** An async method returning `this` returns `Promise<this>`, and chaining becomes `await (await x.a()).b()`. Cypress chains because it queues commands; Playwright awaits them.

Create a component on the second test that needs it, not before. A screen touched by one test keeps its locators in that test.

## The page-wide notice

A third kind of object fits neither type: the **page-wide notice**, meaning the toast, snackbar, or status message the application paints loose on the screen instead of inside the region that triggered it. It is not a route, because it has no URL. And it is not nested: the pilot suite scoped one to the triggering page’s own container and **40 of its 50 guest tests broke**, because the application swaps the two regions rather than nesting them.

Two exits are honest, and which one to take is the adopting project’s call:

- **take `Page`**, and stand outside the two-type contract;
- **take `page.locator("body")`**, and enter as a nested component whose parent is the document.

The first keeps the contract clean and leaves one UI object without one. The second keeps every UI object under the same contract and pays with a root that scopes nothing. Naming the exception is what stops the next author from scoping a notice the application never nested.

## What this gives up

Two indirections now sit between the test and the element (test, component, test id, element), so the selector is not on screen when you read the spec. And someone arriving from another Playwright project will look for `pages/` and not find it. The nesting above pays for both, because it is the only thing that makes region-scoped test ids fail where they are wrong.
