---
name: playwright-trace
description: Inspect Playwright trace files from the command line, listing actions, requests, console output, errors, snapshots, and screenshots.
allowed-tools: Bash(npx:*)
---

# Playwright trace CLI

Inspect `.zip` trace files produced by Playwright tests without opening a browser. This skill covers the full command set: opening a trace, listing actions and requests, reading console output and errors, and querying the DOM snapshot captured at any action.

Invoke the `/playwright` skill when the trace comes from an E2E suite test, because the fix belongs to one of its rules.

## Workflow

Six steps take you from a trace file to the cause of a failure:

1. Run `trace open <trace.zip>` to extract the trace and see its metadata.
2. Run `trace actions` to see all actions with their action IDs.
3. Run `trace action <action-id>` to drill into one action, which shows parameters, logs, source location, and available snapshots.
4. Run `trace requests`, `trace console`, or `trace errors` for cross-cutting views.
5. Run `trace snapshot <action-id>` to get the DOM snapshot, or to run a browser command against it.
6. Run `trace close` to remove the extracted trace data when done.

All commands after `open` operate on the currently opened trace, so you never pass the trace file again. Opening a new trace replaces the previous one.

## Commands

Every command below runs through `npx playwright trace`.

### Open a trace

Extracting a trace prints its metadata: browser, viewport, duration, and action and error counts.

```bash
npx playwright trace open <trace.zip>
```

### Close a trace

Closing removes the extracted trace data from disk.

```bash
npx playwright trace close
```

### Actions

The action list is a tree, carrying the action IDs every other command takes, plus timing. Two filters narrow it:

```bash
npx playwright trace actions

# filter by action title (regex, case-insensitive)
npx playwright trace actions --grep "click"

# only failed actions
npx playwright trace actions --errors-only
```

### Action details

One action expands into its params, result, logs, source, and snapshots. The output names the available snapshot phases (before, input, after) and the exact command to extract them.

```bash
npx playwright trace action <action-id>
```

### Requests

The request list carries method, status, URL, duration, and size for every network request. Three filters narrow it:

```bash
npx playwright trace requests

# filter by URL pattern
npx playwright trace requests --grep "api"

# filter by HTTP method
npx playwright trace requests --method POST

# only failed requests (status >= 400)
npx playwright trace requests --failed
```

### Request details

One request expands into its headers, body, and security details.

```bash
npx playwright trace request <request-id>
```

### Console

The console view merges browser console messages with stdout and stderr. Three filters split them apart:

```bash
npx playwright trace console

# only errors
npx playwright trace console --errors-only

# only browser console
npx playwright trace console --browser

# only stdout and stderr
npx playwright trace console --stdio
```

### Errors

Errors print with their stack traces and the actions they belong to.

```bash
npx playwright trace errors
```

### Snapshots

The `snapshot` command loads the DOM snapshot for an action into a headless browser and runs a single browser command against it. Without a browser command, it returns the accessibility snapshot. Only three browser commands work on a frozen snapshot: `snapshot`, `eval`, and `screenshot`.

```bash
# accessibility snapshot (default)
npx playwright trace snapshot <action-id>

# a specific phase
npx playwright trace snapshot <action-id> --name before

# query the DOM
npx playwright trace snapshot <action-id> -- eval "document.title"
npx playwright trace snapshot <action-id> -- eval "document.querySelector('#error').textContent"

# eval on a specific element ref from the snapshot
npx playwright trace snapshot <action-id> -- eval "el => el.getAttribute('data-testid')" e5

# screenshot the snapshot
npx playwright trace snapshot <action-id> -- screenshot

# redirect output to a file
npx playwright trace snapshot <action-id> -- eval "document.body.outerHTML" --filename=page.html
npx playwright trace snapshot <action-id> -- screenshot --filename=screenshot.png
```

### Attachments

Attachments are listed by number, and extracted by that number.

```bash
npx playwright trace attachments

npx playwright trace attachment 1
npx playwright trace attachment 1 -o out.png
```

## Typical investigation

This sequence takes a failing test from its trace file to the DOM state that explains the failure:

```bash
# 1. open the trace and see what is inside
npx playwright trace open test-results/my-test/trace.zip

# 2. what actions ran?
npx playwright trace actions

# 3. which action failed?
npx playwright trace actions --errors-only

# 4. what went wrong?
npx playwright trace action 12

# 5. what did the page look like at that moment?
npx playwright trace snapshot 12

# 6. query the DOM for more detail
npx playwright trace snapshot 12 -- eval "document.querySelector('.error-message').textContent"

# 7. any relevant network failures?
npx playwright trace requests --failed

# 8. any console errors?
npx playwright trace console --errors-only
```
