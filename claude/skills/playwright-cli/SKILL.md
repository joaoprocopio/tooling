---
name: playwright-cli
description: Drive a browser from the command line with playwright-cli. Use to navigate and interact with a page, snapshot its accessibility tree, inspect console and network, mock requests, manage cookies and storage, record traces and video, or generate and heal Playwright tests.
allowed-tools: Bash(playwright-cli:*) Bash(npx:*) Bash(npm:*)
---

# Browser automation with playwright-cli

Drive a real browser from the command line: navigate, snapshot the page, interact with elements by ref, and inspect console and network. This page covers the command set and the core concepts (snapshots, refs, sessions, raw output); the reference files at the bottom cover the deeper tasks.

Invoke the `/playwright` skill when this session produces E2E suite code, meaning a spec file, a config, or a selector a test will use.

## First session

A session opens a browser, acts on it through refs taken from the snapshot, and closes it:

```bash
# open new browser
playwright-cli open
# navigate to a page
playwright-cli goto https://playwright.dev
# interact with the page using refs from the snapshot
playwright-cli click e15
playwright-cli type "page.click"
playwright-cli press Enter
# take a screenshot (rarely needed, since the snapshot is more useful)
playwright-cli screenshot
# close the browser
playwright-cli close
```

## Commands

### Core

Open a browser, and optionally navigate in the same call:

```bash
playwright-cli open
# open and navigate right away
playwright-cli open https://example.com/
playwright-cli goto https://playwright.dev
playwright-cli close
```

Act on elements through their refs. The `--submit` flag presses Enter after filling:

```bash
playwright-cli type "search query"
playwright-cli click e3
playwright-cli dblclick e7
playwright-cli fill e5 "user@example.com" --submit
playwright-cli drag e2 e8
playwright-cli hover e4
playwright-cli select e9 "option-value"
playwright-cli upload ./document.pdf
playwright-cli check e12
playwright-cli uncheck e12
```

Drop files or data onto an element from outside the page:

```bash
playwright-cli drop e4 --path=./image.png
playwright-cli drop e4 --data="text/plain=hello world"
```

Read the page, search it, and evaluate against it. Use `find` to search a snapshot for text or a regexp, which returns the matching nodes with surrounding context. Wrap the regexp in slashes to add flags, such as `/i` for case-insensitive:

```bash
playwright-cli snapshot
playwright-cli find "Sign in"
playwright-cli find --regex "Sign (in|up)"
playwright-cli find --regex "/sign (in|up)/i"
playwright-cli eval "document.title"
playwright-cli eval "el => el.textContent" e5
# read an id, class, or any attribute the snapshot does not show
playwright-cli eval "el => el.id" e5
playwright-cli eval "el => el.getAttribute('data-testid')" e5
```

Answer dialogs and resize the viewport:

```bash
playwright-cli dialog-accept
playwright-cli dialog-accept "confirmation text"
playwright-cli dialog-dismiss
playwright-cli resize 1920 1080
```

### Navigation

History navigation matches the browser’s own buttons:

```bash
playwright-cli go-back
playwright-cli go-forward
playwright-cli reload
```

### Keyboard

Press a key, or hold one down across several commands with `keydown` and `keyup`:

```bash
playwright-cli press Enter
playwright-cli press ArrowDown
playwright-cli keydown Shift
playwright-cli keyup Shift
```

### Mouse

Mouse commands take page coordinates, and the button defaults to left:

```bash
playwright-cli mousemove 150 300
playwright-cli mousedown
playwright-cli mousedown right
playwright-cli mouseup
playwright-cli mouseup right
playwright-cli mousewheel 0 100
```

### Save as

Capture the page, one element, or the whole document as PDF:

```bash
playwright-cli screenshot
playwright-cli screenshot e5
playwright-cli screenshot --filename=page.png
playwright-cli screenshot --hires
playwright-cli pdf --filename=page.pdf
```

### Tabs

Tabs are addressed by index, and `tab-new` accepts a URL:

```bash
playwright-cli tab-list
playwright-cli tab-new
playwright-cli tab-new https://example.com/page
playwright-cli tab-close
playwright-cli tab-close 2
playwright-cli tab-select 0
```

### Storage

Save and restore the whole storage state, which is how you carry a login between sessions:

```bash
playwright-cli state-save
playwright-cli state-save auth.json
playwright-cli state-load auth.json
```

Cookies are read and written individually, or cleared as a set:

```bash
playwright-cli cookie-list
playwright-cli cookie-list --domain=example.com
playwright-cli cookie-get session_id
playwright-cli cookie-set session_id your_session_value_here
playwright-cli cookie-set session_id your_session_value_here --domain=example.com --httpOnly --secure
playwright-cli cookie-delete session_id
playwright-cli cookie-clear
```

`localStorage` and `sessionStorage` follow the same four verbs:

```bash
playwright-cli localstorage-list
playwright-cli localstorage-get theme
playwright-cli localstorage-set theme dark
playwright-cli localstorage-delete theme
playwright-cli localstorage-clear

playwright-cli sessionstorage-list
playwright-cli sessionstorage-get step
playwright-cli sessionstorage-set step 3
playwright-cli sessionstorage-delete step
playwright-cli sessionstorage-clear
```

### Network

Routes intercept matching requests and answer them with a status or a body:

```bash
playwright-cli route "**/*.jpg" --status=404
playwright-cli route "https://api.example.com/**" --body='{"mock": true}'
playwright-cli route-list
playwright-cli unroute "**/*.jpg"
playwright-cli unroute
```

### DevTools

Read what the page logged and requested, and run arbitrary Playwright code against it:

```bash
playwright-cli console
playwright-cli console warning
playwright-cli requests
playwright-cli request 5
playwright-cli run-code "async page => await page.context().grantPermissions(['geolocation'])"
playwright-cli run-code --filename=script.js
```

Record a trace or a video of the session. Chapters mark points of interest in the video:

```bash
playwright-cli tracing-start
playwright-cli tracing-stop
playwright-cli video-start video.webm
playwright-cli video-chapter "Chapter Title" --description="Details" --duration=2000
playwright-cli video-stop
```

Annotate each subsequent action with a callout naming it and highlighting its target, which makes a recorded video readable:

```bash
playwright-cli video-show-actions --duration=600 --position=top-right
playwright-cli video-hide-actions
```

Launch the dashboard for UI review or design feedback. The user annotates the page, and you receive the annotated screenshot, the snapshot, and the notes:

```bash
playwright-cli show --annotate
```

Generate a Playwright locator for an element, and highlight elements on the page while you work:

```bash
playwright-cli generate-locator e5 --raw
playwright-cli highlight e5
playwright-cli highlight e5 --style="outline: 3px dashed red"
# hide one highlight, or every highlight when no target is given
playwright-cli highlight e5 --hide
playwright-cli highlight --hide
```

## Raw output

The global `--raw` option strips page status, generated code, and snapshot sections from the output, returning only the result value. Use it to pipe command output into other tools. Commands that produce no output return nothing.

```bash
playwright-cli --raw eval "JSON.stringify(performance.timing)" | jq '.loadEventEnd - .navigationStart'
playwright-cli --raw eval "JSON.stringify([...document.querySelectorAll('a')].map(a => a.href))" > links.json
playwright-cli --raw snapshot > before.yml
playwright-cli click e5
playwright-cli --raw snapshot > after.yml
diff before.yml after.yml
TOKEN=$(playwright-cli --raw cookie-get session_id)
playwright-cli --raw localstorage-get theme
```

To wrap every reply as JSON instead, pass `--json`:

```bash
playwright-cli list --json
```

## Open parameters

Choose the browser engine when creating the session:

```bash
playwright-cli open --browser=chrome
playwright-cli open --browser=firefox
playwright-cli open --browser=webkit
playwright-cli open --browser=msedge
```

Emulate a mobile device: `--mobile` picks a generic one (Pixel 10 for Chromium, iPhone 17 for WebKit). Prefer it whenever a mobile layout is acceptable, because mobile pages carry less markup, so snapshots are smaller and cheaper:

```bash
playwright-cli open --mobile
playwright-cli open --device="iPhone 15"
```

Profiles are in-memory by default. Make one persistent to keep cookies and storage between runs:

```bash
playwright-cli open --persistent
playwright-cli open --profile=/path/to/profile
```

Attach to a browser already running, through the Playwright extension or through a Chrome DevTools Protocol (CDP) endpoint:

```bash
playwright-cli attach --extension=chrome
playwright-cli attach --cdp=chrome
playwright-cli attach --cdp=msedge
playwright-cli attach --cdp=http://localhost:9222
```

Start from a config file, then close, detach, or delete the session’s data:

```bash
playwright-cli open --config=my-config.json
playwright-cli close
# detach leaves the external browser running
playwright-cli -s=msedge detach
playwright-cli delete-data
```

## URLs with `&` on Windows

On Windows, `cmd.exe` and PowerShell treat `&` as a command separator, so URLs with multiple query parameters get truncated before `playwright-cli` runs. Escape `&` with `^&` in `cmd.exe`, or use `--%` in PowerShell:

```batch
playwright-cli goto "https://example.com/?a=1^&b=2"
```

```powershell
playwright-cli --% goto "https://example.com/?a=1&b=2"
```

## Snapshots

After each command, playwright-cli returns a snapshot of the current browser state:

```bash
> playwright-cli goto https://example.com
### Page
- Page URL: https://example.com/
- Page Title: Example Domain
### Snapshot
[Snapshot](.playwright-cli/page-2026-02-14T19-22-42-679Z.yml)
```

You can also take a snapshot on demand with `playwright-cli snapshot`, and every option below combines with the others:

```bash
# default: save to a file with a timestamp-based name
playwright-cli snapshot

# save to a named file, for when the snapshot is part of the result
playwright-cli snapshot --filename=after-click.yaml

# snapshot one element instead of the whole page
playwright-cli snapshot "#main"

# limit depth for efficiency, then take a partial snapshot afterwards
playwright-cli snapshot --depth=4
playwright-cli snapshot e34

# include each element's bounding box as [box=x,y,width,height]
playwright-cli snapshot --boxes
```

On a large page, search the snapshot instead of capturing all of it. `find` returns the matching nodes with 3 lines of context around each match, the way `grep -C` does:

```bash
playwright-cli find "Add to cart"
playwright-cli find --regex "\\$[0-9]+\\.[0-9]{2}"
```

## Targeting elements

By default, use refs from the snapshot to interact with page elements:

```bash
# get snapshot with refs
playwright-cli snapshot

# interact using a ref
playwright-cli click e15
```

CSS selectors and Playwright locators work too:

```bash
# css selector
playwright-cli click "#main > button.submit"

# role locator
playwright-cli click "getByRole('button', { name: 'Submit' })"

# test id
playwright-cli click "getByTestId('submit-button')"
```

## Browser sessions

Named sessions run side by side, each with its own browser. Pass `-s=<name>` to every command that belongs to a session:

```bash
# create a new session named "mysession" with a persistent profile
playwright-cli -s=mysession open example.com --persistent
# same, with the profile directory named explicitly
playwright-cli -s=mysession open example.com --profile=/path/to/profile
playwright-cli -s=mysession click e6
# stop that browser
playwright-cli -s=mysession close
# delete the user data of that persistent session
playwright-cli -s=mysession delete-data
```

Three commands act across every session at once:

```bash
playwright-cli list
# close all browsers
playwright-cli close-all
# forcefully kill all browser processes
playwright-cli kill-all
```

## Installation

When the global `playwright-cli` command is missing, check for a local version first:

```bash
npx --no-install playwright --version
```

When a local version answers, use `npx playwright cli` in place of `playwright-cli` in every command. Otherwise install it globally:

```bash
npm install -g @playwright/cli@latest
```

## Example: form submission

Snapshot the page to get refs, fill the fields, then submit:

```bash
playwright-cli open https://example.com/form
playwright-cli snapshot

playwright-cli fill e1 "user@example.com"
playwright-cli fill e2 "your_password_here"
playwright-cli click e3
playwright-cli snapshot
playwright-cli close
```

## Example: multi-tab workflow

Open a second tab, list both, and act on the first:

```bash
playwright-cli open https://example.com
playwright-cli tab-new https://example.com/other
playwright-cli tab-list
playwright-cli tab-select 0
playwright-cli snapshot
playwright-cli close
```

## Example: debugging with DevTools

Act on the page, then read what it logged and requested:

```bash
playwright-cli open https://example.com
playwright-cli click e4
playwright-cli fill e7 "test"
playwright-cli console
playwright-cli requests
playwright-cli close
```

Wrap the same actions in a trace when you want to inspect them afterwards:

```bash
playwright-cli open https://example.com
playwright-cli tracing-start
playwright-cli click e4
playwright-cli fill e7 "test"
playwright-cli tracing-stop
playwright-cli close
```

## Example: interactive session

Ask the user for UI review or design feedback. The user draws boxes on the live page and types comments, and you receive the annotated screenshot, the snapshot of the marked region, and the user’s notes. Use this whenever the user asks for a UI review, for design feedback, or asks you to check what they think, want, or mean:

```bash
playwright-cli open https://example.com
playwright-cli show --annotate
```

## Specific tasks

Nine reference files cover the deeper tasks:

- [Running and debugging Playwright tests](references/playwright-tests.md)
- [Request mocking](references/request-mocking.md)
- [Running Playwright code](references/running-code.md)
- [Browser session management](references/session-management.md)
- [Storage state: cookies and localStorage](references/storage-state.md)
- [Test generation: plan, generate, heal](references/test-generation.md)
- [Tracing](references/tracing.md)
- [Video recording](references/video-recording.md)
- [Inspecting element attributes](references/element-attributes.md)
