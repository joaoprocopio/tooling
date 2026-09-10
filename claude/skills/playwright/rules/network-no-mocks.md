---
title: Exercise the real backend instead of mocking the network
impact: HIGH
tags: [network, mocking, fidelity]
---

Every test exercises the real backend of the targeted environment, end to end, so `page.route()` has no place in the E2E suite. A mock stops validating the actual deploy and creates disguised behavior variation between tests.

Error paths the real environment cannot produce on demand, such as HTTP 500, a malformed payload, or a third party being down, belong to the cheaper layers: frontend integration and unit tests. Pushing them into E2E buys nothing those layers do not already prove, and costs fidelity.

Freezing the browser clock with `page.clock` against a real backend creates the same problem: two clocks that diverge, and failures that are hard to diagnose. Restrict clock mocking to purely client-side behavior, such as how a relative date renders.
