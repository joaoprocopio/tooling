# Video recording

Capture browser automation sessions as video for debugging, documentation, or verification. The output is WebM, using the VP8 or VP9 codec.

## Recording from the command line

Open the browser, start recording, and mark section transitions with chapters as you go:

```bash
# open browser first
playwright-cli open

# start recording
playwright-cli video-start demo.webm

# add a chapter marker for section transitions
playwright-cli video-chapter "Getting Started" --description="Opening the homepage" --duration=2000

# navigate and perform actions
playwright-cli goto https://example.com
playwright-cli snapshot
playwright-cli click e1

# add another chapter
playwright-cli video-chapter "Filling Form" --description="Entering test data" --duration=2000
playwright-cli fill e2 "test input"

# stop and save
playwright-cli video-stop
```

## Name recordings for their content

Put the flow and the run in the filename, so a directory of recordings stays readable:

```bash
playwright-cli video-start recordings/login-flow-2024-01-15.webm
playwright-cli video-start recordings/checkout-test-run-42.webm
```

## Record a full scripted walkthrough

When recording a video for the user, or as proof of work, write a code snippet and execute it with `run-code` rather than driving the browser command by command. A script can insert pauses between actions and annotate the video through the `page.screencast` API.

Three steps produce one:

1. Perform the scenario through the CLI and note every locator and action. You need those locators to request their bounding boxes for highlighting.
2. Write the script file, following the example below. Use `pressSequentially` with a delay for natural typing, and leave reasonable pauses.
3. Run `playwright-cli run-code --filename your-script.js`.

Overlays are `pointer-events: none`, so they never interfere with page interactions. You can keep sticky overlays visible while clicking, filling, or performing any action on the page.

The script below records a TodoMVC walkthrough end to end: it opens a chapter card, types an item, adds a sticky annotation that survives further actions, and finally highlights a located element with a caption positioned from its bounding box.

```js
async page => {
  const size = { width: 1280, height: 800 };
  await page.screencast.start({ path: 'video.webm', size });
  await page.goto('https://demo.playwright.dev/todomvc');

  // blurs the page, shows a dialog, blocks until duration expires, then auto-removes
  await page.screencast.showChapter('Adding Todo Items', {
    description: 'We will add several items to the todo list.',
    duration: 2000,
  });

  const input = page.getByRole('textbox', { name: 'What needs to be done?' });
  await input.pressSequentially('Walk the dog', { delay: 60 });
  await input.press('Enter');
  await page.waitForTimeout(1000);

  await page.screencast.showChapter('Verifying Results', {
    description: 'Checking the item appeared in the list.',
    duration: 2000,
  });

  // sticky annotation: no duration, so it stays until disposed
  const annotation = await page.screencast.showOverlay(`
    <div style="position: absolute; top: 8px; right: 8px;
      padding: 6px 12px; background: rgba(0,0,0,0.7);
      border-radius: 8px; font-size: 13px; color: white;">
      ✓ Item added successfully
    </div>
  `);

  await input.pressSequentially('Buy groceries', { delay: 60 });
  await input.press('Enter');
  await page.waitForTimeout(1500);

  await annotation.dispose();

  // highlight a located element, positioning the caption from its bounding box
  const bounds = await page.getByText('Walk the dog').boundingBox();
  await page.screencast.showOverlay(`
    <div style="position: absolute;
      top: ${bounds.y}px;
      left: ${bounds.x}px;
      width: ${bounds.width}px;
      height: ${bounds.height}px;
      border: 1px solid red;">
    </div>
    <div style="position: absolute;
      top: ${bounds.y + bounds.height + 5}px;
      left: ${bounds.x + bounds.width / 2}px;
      transform: translateX(-50%);
      padding: 6px;
      background: #808080;
      border-radius: 10px;
      font-size: 14px;
      color: white;">Check it out, it is right above this text
    </div>
  `, { duration: 2000 });

  await page.screencast.stop();
}
```

For anything the built-in chapter card does not cover, hand-craft the overlay with `page.screencast.showOverlay()`.

### Overlay API summary

| Method | Use case |
|--------|----------|
| `page.screencast.showChapter(title, { description?, duration?, styleSheet? })` | Full-screen chapter card with blurred backdrop, for section transitions |
| `page.screencast.showOverlay(html, { duration? })` | Custom HTML overlay, for callouts, labels, and highlights |
| `disposable.dispose()` | Remove a sticky overlay added without a duration |
| `page.screencast.hideOverlays()` and `page.screencast.showOverlays()` | Hide or show all overlays temporarily |

## Choosing between video and tracing

| Feature | Video | Tracing |
|---------|-------|---------|
| Output | WebM file | Trace file, viewable in Trace Viewer |
| Shows | Visual recording | DOM snapshots, network, console, actions |
| Use case | Demos, documentation | Debugging, analysis |
| Size | Larger | Smaller |

## Limitations

- Recording adds overhead to automation
- Large recordings consume disk space
