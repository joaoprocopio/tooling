# Browser session management

Run multiple isolated browser sessions concurrently, with state persistence. A session is one browser: name it with `-s`, and every command carrying that name acts on it alone.

## Named browser sessions

The `-s` flag isolates browser contexts, so two sessions never share cookies or storage:

```bash
# browser 1: authentication flow
playwright-cli -s=auth open https://app.example.com/login

# browser 2: public browsing, with separate cookies and storage
playwright-cli -s=public open https://example.com

# commands are isolated by browser session
playwright-cli -s=auth fill e1 "user@example.com"
playwright-cli -s=public snapshot
```

Each browser session has its own:

- Cookies
- `localStorage` and `sessionStorage`
- IndexedDB
- Cache
- Browsing history
- Open tabs

## Session commands

List, stop, and clean up sessions. Use `kill-all` for stale or zombie processes, and `delete-data` to remove a persistent session’s profile directory:

```bash
# list all browser sessions
playwright-cli list

# stop a browser session
playwright-cli close                # the default browser
playwright-cli -s=mysession close   # a named browser

# stop all browser sessions
playwright-cli close-all

# forcefully kill all daemon processes
playwright-cli kill-all

# delete browser session user data
playwright-cli delete-data                # the default browser
playwright-cli -s=mysession delete-data   # a named browser
```

## Setting a default session name

An environment variable makes every command use one session without repeating `-s`:

```bash
export PLAYWRIGHT_CLI_SESSION="mysession"
playwright-cli open example.com  # uses "mysession" automatically
```

## Patterns that use several sessions

Two tasks justify running sessions in parallel.

### Concurrent scraping

Start every browser at once, then collect the snapshots and close them together:

```bash
#!/bin/bash
# scrape multiple sites concurrently

playwright-cli -s=site1 open https://site1.com &
playwright-cli -s=site2 open https://site2.com &
playwright-cli -s=site3 open https://site3.com &
wait

playwright-cli -s=site1 snapshot
playwright-cli -s=site2 snapshot
playwright-cli -s=site3 snapshot

playwright-cli close-all
```

### Comparing two variants

One session per variant keeps their cookies apart, which is what makes the comparison valid:

```bash
playwright-cli -s=variant-a open "https://app.com?variant=a"
playwright-cli -s=variant-b open "https://app.com?variant=b"

playwright-cli -s=variant-a screenshot
playwright-cli -s=variant-b screenshot
```

## Persistent profiles

A browser profile is kept in memory only. Pass `--persistent` on `open` to write it to disk instead:

```bash
# persistent profile in an auto-generated location
playwright-cli open https://example.com --persistent

# persistent profile in a directory you name
playwright-cli open https://example.com --profile=/path/to/profile
```

## Attaching to a running browser

Use `attach` to connect to a browser that is already running, instead of launching a new one.

### Attach by channel name

Connect to a running Chrome or Edge instance by its channel name. The browser needs remote debugging enabled first: navigate to `chrome://inspect/#remote-debugging` in the target browser and check “Allow remote debugging for this browser instance”.

```bash
playwright-cli attach --cdp=chrome
playwright-cli attach --cdp=chrome-canary
playwright-cli attach --cdp=msedge
playwright-cli attach --cdp=msedge-dev
```

The supported channels are `chrome`, `chrome-beta`, `chrome-dev`, `chrome-canary`, `msedge`, `msedge-beta`, `msedge-dev`, and `msedge-canary`.

Without `--session`, the session takes the channel’s name, so `--cdp=msedge` creates a session called `msedge` and parallel attaches to Chrome and Edge never collide on `default`. Pass `--session=<name>` to override that.

### Attach through a CDP endpoint

Connect to a browser exposing a Chrome DevTools Protocol (CDP) endpoint:

```bash
playwright-cli attach --cdp=http://localhost:9222
```

### Attach through the browser extension

Connect to a browser running the Playwright extension:

```bash
playwright-cli attach --extension
```

### Detach

Tear down an attached session while leaving the external browser running:

```bash
# detach the default attached session
playwright-cli detach

# detach a specific attached session
playwright-cli -s=msedge detach
```

`detach` works only on sessions created with `attach`. For sessions created with `open`, use `close`.

## The default session

When `-s` is omitted, commands act on the default browser session:

```bash
# these use the same default browser session
playwright-cli open https://example.com
playwright-cli snapshot
playwright-cli close
```

## Configuring a session at open time

Pass the browser, the display mode, the profile, or a whole config file when opening:

```bash
playwright-cli open https://example.com --config=.playwright/my-cli.json
playwright-cli open https://example.com --browser=firefox
playwright-cli open https://example.com --headed
playwright-cli open https://example.com --persistent
```

## Three habits that keep sessions manageable

**Name sessions for their purpose**, so `list` stays readable:

```bash
# clear purpose
playwright-cli -s=github-auth open https://github.com
playwright-cli -s=docs-scrape open https://docs.example.com

# avoid generic names
playwright-cli -s=s1 open https://github.com
```

**Always clean up**, because a session left open holds a browser process:

```bash
playwright-cli -s=auth close
playwright-cli -s=scrape close

# or stop all at once
playwright-cli close-all

# when browsers become unresponsive or zombie processes remain
playwright-cli kill-all
```

**Delete stale browser data** to free disk space:

```bash
playwright-cli -s=oldsession delete-data
```
