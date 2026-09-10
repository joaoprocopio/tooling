# Bitbucket — `twg bb pull-requests`, verified against twg 1.2.7

Hosts: `bitbucket.org`
Detect: `git remote get-url origin` matches the host above, and `twg` is on PATH. On `command not found`, try `$HOME/.local/bin/twg`; when that also fails, stop and tell the user `twg` is missing.

`twg` auto-detects `-w <workspace>` and `-r <repo>` from the git remote of the working directory. Pass both explicitly whenever a command runs outside the PR's own checkout, which is every command on a **pair**.

Read the auth guard in the `twg` skill before running anything: on an auth error, report the remediation and wait, rather than running a login or setup command.

## Output

A step that parses output asks for JSON and reads the envelope:

```bash
twg bb pull-requests <cmd> --output json --output-summary stats
```

That prints a YAML envelope on stdout and writes the full payload to a file. Read `stdout_inline` when it is present and complete; otherwise read the path under `output_files.compact`. There is **no `--output-file` flag** — do not pass one.

`-o json` alone puts the whole payload on stdout, which is fine for a small read like `get` and wasteful for `comment query` on a busy PR.

## Argument shape

The two halves of the CLI disagree, so check the column before writing a command:

- **Reads take the PR id as a positional**: `get <id>`, `diff <id>`, `diff-line <id>`, `comment query <id>`, `task query <id>`, `approve <id>`.
- **Writes take it as a flag**: `--pull-request <id>` on every `comment` and `task` write, and on `update`.

## Operations

| Operation        | Command                                                                                                                                     |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `pr.identity`    | `twg bb pull-requests get <id> -o json`                                                                                                     |
| `pr.diff`        | `twg bb pull-requests diff <id>`                                                                                                            |
| `pr.diff-line`   | `twg bb pull-requests diff-line <id> --text "<distinctive text>" [--path <file>]`                                                           |
| `thread.list`    | `twg bb pull-requests comment query <id> --output json --output-summary stats`                                                              |
| `thread.create`  | `twg bb pull-requests comment create --pull-request <id> [--path <file> --line <n>] --text "$(cat <body.md>)"`                              |
| `thread.reply`   | `twg bb pull-requests comment create --pull-request <id> --reply-to <thread-id> --text "$(cat <body.md>)"`                                  |
| `thread.resolve` | `twg bb pull-requests comment resolve --pull-request <id> --comment <thread-id>`                                                            |
| `blocker.list`   | `twg bb pull-requests task query <id> -o json`                                                                                              |
| `checks.read`    | `twg bb pull-requests get <id> --statuses -o json`                                                                                          |
| `verdict`        | `twg bb pull-requests approve <id>` / `request-changes <id>` / `decline <id>`                                                               |
| `pr.create`      | `twg bb pull-requests create --title "..." --source <branch> --dest <branch> --description-file <file.md> [--reviewer <user>]... [--draft]` |
| `pr.update`      | `twg bb pull-requests update --pull-request <id> --title "..." --description-file <file.md> [--ready] [--add-reviewer <user>]`              |

`pr.identity` reads the fields from these paths: target is `destination.branch.name`, source branch `source.branch.name`, head SHA `source.commit.hash`, and source repo `source.repository.full_name`, which differs from the destination's on a fork.

## Anchors

`comment create` takes the anchor flags directly, and they are the four the contract names:

- `--path <file> --line <n>` — new side, the added or destination side.
- `--path <file> --from-line <n>` — old side; a deleted file takes only this.
- `--path <file> --start-line <a> --end-line <b>` — a range on the new side, which is what a multi-line suggestion takes. `--start-from-line`/`--end-from-line` is the old-side range.
- no `--path` — general.

Take every line number from `diff-line` rather than from the local file. A rejected post is the server refusing the anchor: re-run `diff-line` and re-anchor rather than retrying the same number.

## Threads

Every comment write takes `--comment <id>`, and resolution takes the **top-level** comment's ID, so a thread ID is the ID of the comment that opens the thread. Replies cannot be resolved, reopened, or replied to.

In `comment query` output, each comment holds its anchor in `inline.path`, `inline.to`, and `inline.from`, and `parent.id` when it is a reply. `resolution` is a non-empty object when the thread is resolved; `deleted` and `pending` are flags. A thread is **live** when its opening comment has no `parent`, is not `deleted`, and carries an empty `resolution`.

`comment reopen --pull-request <id> --comment <thread-id>` reopens one that closed early.

## Blockers

Bitbucket serves blockers first-class, so a blocker becomes a real task rather than a line in a comment. A task is its own object with its own ID, attached to a thread through `--comment <thread-id>` or standing alone:

```bash
twg bb pull-requests task create  --pull-request <id> --text "..." [--comment <thread-id>]
twg bb pull-requests task query   <id> -o json          # maps task IDs to their threads
twg bb pull-requests task resolve --pull-request <id> --task <task-id>
twg bb pull-requests task reopen  --pull-request <id> --task <task-id>
```

A task ID differs from the thread ID it hangs off, so read `task query` whenever a step needs one. A blocker takes both halves: the inline thread carries the finding and the evidence, and the task carries the one-line ask that gates the merge.

## Checks

`get <id> --statuses` returns the builds reported on the head under `_statuses`, each with a `name`, a `state` of `SUCCESSFUL`, `FAILED`, `INPROGRESS`, or `STOPPED`, and a `url`. An empty list means no build reports to this PR. There is no wait flag: a build still `INPROGRESS` is re-read after a pause sized to the pipeline's usual run.

A failed build reads its log through the pipeline, not the PR:

```bash
twg bb pipeline latest-failure --branch <source-branch> [--lines 200]
```

If a sandboxed pipeline log request shows a network-blocked message, an S3 hostname, or a log-only HTTP 403 while metadata succeeds, that is a sandbox restriction, not an auth failure.

## Reviewers

`twg bb pull-requests effective-default-reviewer query` lists the reviewers the repo adds on its own, so the question `pr-open` puts to the user is who joins them. Confirm them on the read-back after create: a default reviewer missing from it is added with `update --add-reviewer`.

## Not served

- **`--pending` review batching** — `comment create --pending` holds a comment as draft feedback, and `twg` has no command that submits it. A pending comment stays invisible until someone finishes the review in the Bitbucket web UI. Post comments outright unless the user asks for a draft and accepts that hand-off.
- **Applying a suggestion** — no command applies one. Apply a suggestion that came the other way by editing the anchored lines yourself, per `pr`.
- **Checkout** — no command clones or checks out. Fetch the head with `git`, per `pr`.
- **A verdict message** — `approve`, `request-changes`, and `decline` take no text, so the reason goes in a general comment posted first. All three are the reviewer's terminal act and belong to the user: state the verdict you would give and let the user run the command. `unapprove` and `remove-request-changes` withdraw one.
