# Tracing

Capture detailed execution traces for debugging and analysis. A trace holds DOM snapshots, screenshots, network activity, and console logs, which is what makes it the tool for reconstructing why an action failed.

## Recording a trace

Start recording, perform the actions, then stop:

```bash
# start trace recording
playwright-cli tracing-start

# perform actions
playwright-cli open https://example.com
playwright-cli click e1
playwright-cli fill e2 "test"

# stop trace recording
playwright-cli tracing-stop
```

## Trace output files

Starting a trace creates a `traces/` directory holding three kinds of file.

### `trace-{timestamp}.trace`

The action log, and the main trace file. It contains:

- Every action performed: clicks, fills, navigations
- DOM snapshots before and after each action
- Screenshots at each step
- Timing information
- Console messages
- Source locations

### `trace-{timestamp}.network`

The network log, covering complete network activity:

- All HTTP requests and responses
- Request headers and bodies
- Response headers and bodies
- Timing: DNS, connect, TLS, time to first byte (TTFB), download
- Resource sizes
- Failed requests and errors

### `resources/`

The cached resources needed to replay the page:

- Images, fonts, stylesheets, scripts
- Response bodies for replay
- Assets needed to reconstruct page state

## What a trace captures

| Category | Details |
|----------|---------|
| **Actions** | Clicks, fills, hovers, keyboard input, navigations |
| **DOM** | Full DOM snapshot before and after each action |
| **Screenshots** | Visual state at each step |
| **Network** | All requests, responses, headers, bodies, timing |
| **Console** | All console.log, warn, and error messages |
| **Timing** | Precise timing for each operation |

## What traces are for

Three tasks account for most tracing.

### Debugging a failed action

The trace shows the DOM state at the moment of the click, which is what explains the failure:

```bash
playwright-cli tracing-start
playwright-cli open https://app.example.com

# this click fails, and the trace shows why
playwright-cli click e5

playwright-cli tracing-stop
```

### Analyzing performance

The network waterfall in the trace identifies the slow resources:

```bash
playwright-cli tracing-start
playwright-cli open https://slow-site.com
playwright-cli tracing-stop
```

### Capturing evidence

Record a complete user flow, and the trace holds the exact sequence of events:

```bash
playwright-cli tracing-start

playwright-cli open https://app.example.com/checkout
playwright-cli fill e1 "4111111111111111"
playwright-cli fill e2 "12/25"
playwright-cli fill e3 "123"
playwright-cli click e4

playwright-cli tracing-stop
```

## Choosing between trace, video, and screenshot

| Feature | Trace | Video | Screenshot |
|---------|-------|-------|------------|
| **Format** | .trace file | .webm video | .png or .jpeg image |
| **DOM inspection** | Yes | No | No |
| **Network details** | Yes | No | No |
| **Step-by-step replay** | Yes | Continuous | Single frame |
| **File size** | Medium | Large | Small |
| **Best for** | Debugging | Demos | One-off capture |

## Two habits that keep traces useful

**Start tracing before the problem.** Trace the entire flow rather than the failing step alone, because the cause can sit several steps before the failure:

```bash
playwright-cli tracing-start
playwright-cli open https://example.com
# ... all steps leading to the issue ...
playwright-cli tracing-stop
```

**Clean up old traces**, because they accumulate on disk:

```bash
# remove traces older than 7 days
find .playwright-cli/traces -mtime +7 -delete
```

## Limitations

- Tracing adds overhead to automation
- Large traces consume disk space
- Dynamic content does not always replay exactly
