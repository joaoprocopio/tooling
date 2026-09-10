# Running and debugging Playwright tests

Run a suite with `npx playwright test` or a package manager script, and debug a failing test by attaching `playwright-cli` to the paused run.

## Running tests

Run tests with `npx playwright test`, or through the project’s own script. Set `PLAYWRIGHT_HTML_OPEN=never` to keep the interactive HTML report from opening:

```bash
# run all tests
PLAYWRIGHT_HTML_OPEN=never npx playwright test

# run all tests through a custom npm script
PLAYWRIGHT_HTML_OPEN=never npm run special-test-command
```

## Debugging a failing test

Run the failing test with `--debug=cli`. The command pauses the test at the start and prints the debugging instructions.

**IMPORTANT**: run the command in the background and check the output until “Debugging Instructions” is printed. Stop the command once you have finished.

The printed instructions carry a session name. Use it to attach `playwright-cli` to the paused test and explore the page:

```bash
# run the test
PLAYWRIGHT_HTML_OPEN=never npx playwright test --debug=cli
# ...
# ... debugging instructions for "tw-abcdef" session ...
# ...

# attach to the test
playwright-cli attach tw-abcdef
```

Keep the test running in the background while you explore and look for a fix. The test is paused at the start, so step over or pause at the location where the problem is most likely to be.

Every action you perform with `playwright-cli` generates the corresponding Playwright TypeScript code. That code appears in the output and can be copied straight into the test. The fix is most commonly a locator or an expectation, but it can also be a bug in the app, so use your judgment.

After fixing the test, stop the background test run and rerun it to check that the test passes.
