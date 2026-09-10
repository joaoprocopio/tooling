# Storage management

Manage cookies, `localStorage`, `sessionStorage`, IndexedDB, and the combined storage state. Saving the storage state to a file is what lets one session log in and another skip the login entirely.

## Storage state

The storage state is the complete browser state, covering cookies and origin storage together.

Save it to an auto-generated name, or to one you choose:

```bash
# save to storage-state-{timestamp}.json
playwright-cli state-save

# save to a specific filename
playwright-cli state-save my-auth-state.json
```

Load it back, then open the page so the cookies apply:

```bash
playwright-cli state-load my-auth-state.json
playwright-cli open https://example.com
```

The saved file holds a `cookies` array and an `origins` array, one entry per origin:

```json
{
  "cookies": [
    {
      "name": "session_id",
      "value": "your_session_value_here",
      "domain": "example.com",
      "path": "/",
      "expires": 1893456000,
      "httpOnly": true,
      "secure": true,
      "sameSite": "Lax"
    }
  ],
  "origins": [
    {
      "origin": "https://example.com",
      "localStorage": [
        { "name": "theme", "value": "dark" },
        { "name": "user_id", "value": "1234567890123" }
      ]
    }
  ]
}
```

## Cookies

List every cookie, or narrow the list by domain or path:

```bash
playwright-cli cookie-list
playwright-cli cookie-list --domain=example.com
playwright-cli cookie-list --path=/api
```

Read, write, and delete individual cookies. `cookie-set` takes the attributes as flags, and `--expires` takes a Unix timestamp:

```bash
playwright-cli cookie-get session_id

# basic cookie
playwright-cli cookie-set session your_session_value_here

# cookie with options
playwright-cli cookie-set session your_session_value_here --domain=example.com --path=/ --httpOnly --secure --sameSite=Lax

# cookie with expiration
playwright-cli cookie-set remember_me your_remember_token_here --expires=1893456000

playwright-cli cookie-delete session_id
playwright-cli cookie-clear
```

To add several cookies in one call, or to set a value the flags cannot express, use `run-code`:

```bash
playwright-cli run-code "async page => {
  await page.context().addCookies([
    {
      name: 'session_id', value: 'your_session_value_here',
      domain: 'example.com', path: '/', httpOnly: true
    },
    {
      name: 'preferences', value: JSON.stringify({ theme: 'dark' }),
      domain: 'example.com', path: '/'
    }
  ]);
}"
```

## localStorage

Five commands cover the whole surface. A JSON value goes in as a quoted string:

```bash
playwright-cli localstorage-list
playwright-cli localstorage-get token
playwright-cli localstorage-set theme dark
playwright-cli localstorage-set user_settings '{"theme":"dark","language":"en"}'
playwright-cli localstorage-delete token
playwright-cli localstorage-clear
```

To set several values in one call, evaluate against the page:

```bash
playwright-cli run-code "async page => {
  await page.evaluate(() => {
    localStorage.setItem('token', 'your_jwt_here');
    localStorage.setItem('user_id', '1234567890123');
    localStorage.setItem('expires_at', Date.now() + 3600000);
  });
}"
```

## sessionStorage

`sessionStorage` takes the same verbs as `localStorage`, against storage that dies with the tab:

```bash
playwright-cli sessionstorage-list
playwright-cli sessionstorage-get form_data
playwright-cli sessionstorage-set step 3
playwright-cli sessionstorage-delete step
playwright-cli sessionstorage-clear
```

## IndexedDB

IndexedDB has no dedicated commands, so reach it through `run-code`.

List the databases of the current origin:

```bash
playwright-cli run-code "async page => {
  return await page.evaluate(async () => {
    const databases = await indexedDB.databases();
    return databases;
  });
}"
```

Delete one by name:

```bash
playwright-cli run-code "async page => {
  await page.evaluate(() => {
    indexedDB.deleteDatabase('myDatabase');
  });
}"
```

## Reusing an authenticated session

Log in once, save the state, and every later session starts authenticated:

```bash
# step 1: log in and save the state
playwright-cli open https://app.example.com/login
playwright-cli snapshot
playwright-cli fill e1 "user@example.com"
playwright-cli fill e2 "your_password_here"
playwright-cli click e3
playwright-cli state-save auth.json

# step 2: later, restore the state and skip the login
playwright-cli state-load auth.json
playwright-cli open https://app.example.com/dashboard
```

The same roundtrip works for any state, not only authentication:

```bash
# set up the state
playwright-cli open https://example.com
playwright-cli eval "() => { document.cookie = 'session=your_session_value_here'; localStorage.setItem('user', 'john'); }"

# save it to a file
playwright-cli state-save my-session.json

# later, in a new session, restore it
playwright-cli state-load my-session.json
playwright-cli open https://example.com
```

## Keeping storage state files safe

A storage state file carries live credentials, so treat it as a secret:

- Never commit storage state files containing auth tokens
- Add `*.auth-state.json` to `.gitignore`
- Delete state files once the automation completes
- Keep sensitive data in environment variables
- Prefer the default in-memory session for sensitive operations
