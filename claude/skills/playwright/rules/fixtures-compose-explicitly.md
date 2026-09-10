---
title: Wire every fixture in one chain, and name every dependency
impact: HIGH
tags: [fixtures, setup, dependencies]
---

The fixture file is where every layer of the suite is wired, and both of its failure modes are silent. Nothing throws, nothing is reported, and the test passes for a reason the author never intended.

## One `test`, one chain

Several rules extend the same fixtures: `page` is overridden to disable animations, the provisioning service is injected, a persona’s session is planted. Extending the base twice produces two unrelated `test` objects, and a spec imports one of them, so everything the other one set up never runs.

**Incorrect** (two chains; the spec gets whichever it imported):

```ts
// one file
export const test = base.extend({ page: /* animations disabled */ });
// another file
export const test = base.extend<{ api: RsvpApi }>({ api: /* provisioning */ });
```

**Correct** (one chain, exported once):

```ts
export const test = base.extend<{ api: RsvpApi }>({
  page: async ({ page }, use) => {
    /* disable animations */ await use(page);
  },
  api: async ({ playwright, token }, use) => {
    /* provisioning context */
  },
});
```

## Naming a fixture is what runs it

A fixture whose whole job is an effect, such as planting a session cookie, has nothing to hand back. A test depends on it by **naming it in the destructure**, and reading the value is not part of that:

```ts
test("operator opens the dashboard", async ({ page, session }) => {
  // `session` is never read; naming it is what makes it run
});
```

Add a `void session;` line only where a linter actually complains, and check that it does before writing it.

Drop the name and the edge disappears with it. The fixture stops running, the test still executes, and the assertion that depended on that state either meets the application’s default or reads what another test left behind.
