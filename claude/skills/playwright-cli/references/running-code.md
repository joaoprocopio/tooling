# Running custom Playwright code

Use `run-code` to execute arbitrary Playwright code for scenarios the CLI commands do not cover: geolocation, permissions, media emulation, frames, downloads, clipboard, and multi-step workflows.

## Syntax

Pass a single async function that receives the page:

```bash
playwright-cli run-code "async page => {
  // your Playwright code here
  // page.context() reaches the browser context
}"
```

You can also load the function from a file:

```bash
playwright-cli run-code --filename=./my-script.js
```

The code must be a single function expression, which is wrapped in `(...)` and evaluated. The `import`, `export`, and `require` syntax does not work.

## Geolocation

Granting the permission and setting coordinates takes two calls on the context, and `clearPermissions` removes the override:

```bash
# grant geolocation permission and set location
playwright-cli run-code "async page => {
  await page.context().grantPermissions(['geolocation']);
  await page.context().setGeolocation({ latitude: 37.7749, longitude: -122.4194 });
}"

# set location to London
playwright-cli run-code "async page => {
  await page.context().grantPermissions(['geolocation']);
  await page.context().setGeolocation({ latitude: 51.5074, longitude: -0.1278 });
}"

# clear geolocation override
playwright-cli run-code "async page => {
  await page.context().clearPermissions();
}"
```

## Permissions

Grant permissions for the whole context, or scope them to one origin:

```bash
# grant multiple permissions
playwright-cli run-code "async page => {
  await page.context().grantPermissions([
    'geolocation',
    'notifications',
    'camera',
    'microphone'
  ]);
}"

# grant permissions for a specific origin
playwright-cli run-code "async page => {
  await page.context().grantPermissions(['clipboard-read'], {
    origin: 'https://example.com'
  });
}"
```

## Media emulation

`emulateMedia` drives the CSS media features the page responds to, which is how you exercise dark mode, reduced motion, and print styles:

```bash
# emulate dark color scheme
playwright-cli run-code "async page => {
  await page.emulateMedia({ colorScheme: 'dark' });
}"

# emulate light color scheme
playwright-cli run-code "async page => {
  await page.emulateMedia({ colorScheme: 'light' });
}"

# emulate reduced motion
playwright-cli run-code "async page => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
}"

# emulate print media
playwright-cli run-code "async page => {
  await page.emulateMedia({ media: 'print' });
}"
```

## Wait strategies

Four ways to wait, ordered from the vaguest signal to the most specific. Prefer waiting on an element or a condition over waiting on the network:

```bash
# wait for network idle
playwright-cli run-code "async page => {
  await page.waitForLoadState('networkidle');
}"

# wait for a specific element
playwright-cli run-code "async page => {
  await page.locator('.loading').waitFor({ state: 'hidden' });
}"

# wait for a function to return true
playwright-cli run-code "async page => {
  await page.waitForFunction(() => window.appReady === true);
}"

# wait with a timeout
playwright-cli run-code "async page => {
  await page.locator('.result').waitFor({ timeout: 10000 });
}"
```

## Frames and iframes

Reach into an iframe with `contentFrame()`, or list every frame on the page:

```bash
# work with an iframe
playwright-cli run-code "async page => {
  const frame = page.locator('iframe#my-iframe').contentFrame();
  await frame.locator('button').click();
}"

# get all frames
playwright-cli run-code "async page => {
  const frames = page.frames();
  return frames.map(f => f.url());
}"
```

## File downloads

Register the download event *before* the click that triggers it, then save the file where you want it:

```bash
playwright-cli run-code "async page => {
  const downloadPromise = page.waitForEvent('download');
  await page.getByRole('link', { name: 'Download' }).click();
  const download = await downloadPromise;
  await download.saveAs('./downloaded-file.pdf');
  return download.suggestedFilename();
}"
```

## Clipboard

Reading the clipboard needs the `clipboard-read` permission; writing does not:

```bash
# read the clipboard
playwright-cli run-code "async page => {
  await page.context().grantPermissions(['clipboard-read']);
  return await page.evaluate(() => navigator.clipboard.readText());
}"

# write to the clipboard
playwright-cli run-code "async page => {
  await page.evaluate(text => navigator.clipboard.writeText(text), 'Hello clipboard!');
}"
```

## Page information

Four properties of the current page, returned straight to the caller:

```bash
# get page title
playwright-cli run-code "async page => {
  return await page.title();
}"

# get current URL
playwright-cli run-code "async page => {
  return page.url();
}"

# get page content
playwright-cli run-code "async page => {
  return await page.content();
}"

# get viewport size
playwright-cli run-code "async page => {
  return page.viewportSize();
}"
```

## JavaScript execution

`page.evaluate` runs in the page and returns the result. Pass arguments as a second parameter, because the function body cannot close over variables from the outer scope:

```bash
# execute JavaScript and return the result
playwright-cli run-code "async page => {
  return await page.evaluate(() => {
    return {
      userAgent: navigator.userAgent,
      language: navigator.language,
      cookiesEnabled: navigator.cookieEnabled
    };
  });
}"

# pass arguments to evaluate
playwright-cli run-code "async page => {
  const multiplier = 5;
  const count = m => document.querySelectorAll('li').length * m;
  return await page.evaluate(count, multiplier);
}"
```

## Error handling

Catch inside the function and return a value, so a missing element produces an answer instead of a failure:

```bash
playwright-cli run-code "async page => {
  try {
    await page.getByRole('button', { name: 'Submit' }).click({ timeout: 1000 });
    return 'clicked';
  } catch (e) {
    return 'element not found';
  }
}"
```

## Multi-step workflows

A single `run-code` call can carry a whole flow, which is what makes it the tool for logging in once or walking several pages:

```bash
# log in and save the state
playwright-cli run-code "async page => {
  await page.goto('https://example.com/login');
  await page.getByRole('textbox', { name: 'Email' }).fill('user@example.com');
  await page.getByRole('textbox', { name: 'Password' }).fill('your_password_here');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.waitForURL('**/dashboard');
  await page.context().storageState({ path: 'auth.json' });
  return 'Login successful';
}"

# scrape data from multiple pages
playwright-cli run-code "async page => {
  const results = [];
  for (let i = 1; i <= 3; i++) {
    await page.goto(\`https://example.com/page/\${i}\`);
    const items = await page.locator('.item').allTextContents();
    results.push(...items);
  }
  return results;
}"
```
