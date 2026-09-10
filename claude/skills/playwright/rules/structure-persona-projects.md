---
title: Emulate each persona’s real environment
impact: MEDIUM
tags: [structure, projects, devices]
---

Map each product persona to the devices and browsers it actually uses, and route tests by tag. Guests respond on their phones, so `@guest` runs on iPhone WebKit (which covers both Safari and Chrome on iOS), Android Chromium, and Firefox. Operators work on desktop, so `@admin` runs on Desktop Chrome.

```ts
projects: [
  { name: "guest-ios", grep: /@guest/, use: { ...devices["iPhone 13"] } },
  { name: "guest-android", grep: /@guest/, use: { ...devices["Pixel 5"] } },
  { name: "admin-desktop", grep: /@admin/, use: { ...devices["Desktop Chrome"] } },
],
```

The tag lives in the test title, because `grep` is what routes a test to its persona project. A test whose title lost its tag matches no project and is skipped without a word, so it reads as covered and never runs.

The full matrix runs on every execution. Cost grows linearly with test count, so record run duration and revisit the matrix once it slows the execution cadence.

State the emulation limits **in the config file itself**, so the team never counts on coverage that does not exist:

- Desktop WebKit emulating an iPhone is not real iOS Safari.
- Playwright’s Firefox supports neither `isMobile` nor touch events, so a “Firefox mobile” project tests the engine with a mobile viewport and user agent, and nothing more.
- WebKit on Linux CI is not Safari. It is a port with its own graphics stack, sensitive to the runner image, and it raises internal errors that never appear on local macOS. Pin the official Docker image matched to the exact Playwright version, and treat a Playwright upgrade as an environment change.
