# Request mocking

Intercept, mock, modify, and block network requests. The `route` command covers static answers; `run-code` covers everything that has to inspect the request first.

## Route commands

A route matches a URL pattern and answers it with a status, a body, or modified headers:

```bash
# mock with custom status
playwright-cli route "**/*.jpg" --status=404

# mock with JSON body
playwright-cli route "**/api/users" --body='[{"id":1,"name":"Alice"}]' --content-type=application/json

# mock with custom headers
playwright-cli route "**/api/data" --body='{"ok":true}' --header="X-Custom: value"

# remove headers from requests
playwright-cli route "**/*" --remove-header=cookie,authorization

# list active routes
playwright-cli route-list

# remove one route, or all routes
playwright-cli unroute "**/*.jpg"
playwright-cli unroute
```

## URL patterns

Patterns use glob syntax, where `**` matches any number of path segments:

```text
**/api/users           exact path match
**/api/*/details       wildcard in path
**/*.{png,jpg,jpeg}    match file extensions
**/search?q=*          match query parameters
```

## Advanced mocking with run-code

Four cases need `run-code` instead of a static route: conditional responses, request body inspection, response modification, and delays.

### Conditional response based on the request

Read the posted body, then answer differently per case:

```bash
playwright-cli run-code "async page => {
  await page.route('**/api/login', route => {
    const body = route.request().postDataJSON();
    if (body.username === 'admin') {
      route.fulfill({ body: JSON.stringify({ token: 'mock-token' }) });
    } else {
      route.fulfill({ status: 401, body: JSON.stringify({ error: 'Invalid' }) });
    }
  });
}"
```

### Modify a real response

Fetch the real response, change one field, and fulfill with the result:

```bash
playwright-cli run-code "async page => {
  await page.route('**/api/user', async route => {
    const response = await route.fetch();
    const json = await response.json();
    json.isPremium = true;
    await route.fulfill({ response, json });
  });
}"
```

### Simulate network failures

Abort the request with the error the browser would raise. The options are `connectionrefused`, `timedout`, `connectionreset`, and `internetdisconnected`:

```bash
playwright-cli run-code "async page => {
  await page.route('**/api/offline', route => route.abort('internetdisconnected'));
}"
```

### Delay a response

Wait before fulfilling, to reproduce a slow endpoint:

```bash
playwright-cli run-code "async page => {
  await page.route('**/api/slow', async route => {
    await new Promise(r => setTimeout(r, 3000));
    route.fulfill({ body: JSON.stringify({ data: 'loaded' }) });
  });
}"
```
