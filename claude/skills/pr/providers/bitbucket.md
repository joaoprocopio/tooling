# Bitbucket: `twg bb pull-requests`, verified against twg 1.2.7

This adapter serves two things:

- **Hosts**: `bitbucket.org`
- **Detect**: `git remote get-url origin` matches the host above, and `twg` is on PATH. On `command not found`, try `$HOME/.local/bin/twg`; when that also fails, stop and tell the user `twg` is missing.

`twg` auto-detects `-w <workspace>` and `-r <repo>` from the git remote of the working directory. Pass both explicitly whenever a command runs outside the PR's own checkout, which is every command on a **pair**.

On an auth error, report the remediation and wait, rather than running a login or setup command.

## Output

A step that parses output asks for JSON and reads the envelope:

```bash
twg bb pull-requests <cmd> --output json --output-summary stats
```

That prints a YAML envelope on stdout and writes the full payload to a file. Read `stdout_inline` when it is present and complete; otherwise read the path under `output_files.compact`. The envelope is where the path comes from: there is **no `--output-file` flag**.

`-o json` alone puts the whole payload on stdout, which is fine for a small read like `get` and wasteful for `comment query` on a busy PR.

## Argument shape

The two halves of the CLI disagree, so check the column before writing a command:

- **Reads take the PR id as a positional**: `get <id>`, `diff <id>`, `diff-line <id>`, `comment query <id>`, `task query <id>`, `approve <id>`.
- **Writes take it as a flag**: `--pull-request <id>` on every `comment` and `task` write, and on `update`.

## Operations

| Operation         | Command                                                                                                                                              |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pr.identity`     | `twg bb pull-requests get <id> -o json`                                                                                                              |
| `pr.files`        | `twg bb pull-requests diffstat <id> -n 200 -o json`                                                                                                  |
| `pr.diff`         | `twg bb pull-requests diff <id>`                                                                                                                     |
| `pr.diff-line`    | `twg bb pull-requests diff-line <id> --text "<anchor text>" [--path <file>]`                                                                         |
| `thread.list`     | `twg bb pull-requests comment query <id> --output json --output-summary stats`                                                                       |
| `thread.create`   | `twg bb pull-requests comment create --pull-request <id> [--path <file> --line <n>] --text "$(cat <body.md>)"`                                       |
| `thread.reply`    | `twg bb pull-requests comment create --pull-request <id> --reply-to <thread-id> --text "$(cat <body.md>)"`                                           |
| `thread.resolve`  | `twg bb pull-requests comment resolve --pull-request <id> --comment <thread-id>`                                                                     |
| `thread.reopen`   | `twg bb pull-requests comment reopen --pull-request <id> --comment <thread-id>`                                                                      |
| `blocker.list`    | `twg bb pull-requests task query <id> -o json`                                                                                                       |
| `blocker.create`  | `twg bb pull-requests task create --pull-request <id> --text "<the ask>" [--comment <thread-id>]`                                                    |
| `blocker.resolve` | `twg bb pull-requests task resolve --pull-request <id> --task <task-id>`                                                                             |
| `checks.read`     | `twg bb pull-requests get <id> --statuses -o json`                                                                                                   |
| `checks.log`      | `twg bb pipeline latest-failure --branch <source-branch> [--lines 200]`, and `twg bb pipeline grep "<pattern>"` for one assertion out of a long log  |
| `verdict`         | `twg bb pull-requests approve <id>` / `request-changes <id>` / `decline <id>`                                                                        |
| `pr.create`       | `twg bb pull-requests create --title "<title>" --source <branch> --dest <branch> --description-file <file.md> [--reviewer <user>]... [--draft]`      |
| `pr.update`       | `twg bb pull-requests update --pull-request <id> --title "<title>" --description-file <file.md> [--dest <branch>] [--ready] [--add-reviewer <user>]` |
| `pr.reviewers`    | `effective-default-reviewer query -o json` for who the repo adds; `get <id> -o json` `.reviewers` for who is requested                               |
| `pr.queue`        | `twg bb inbox --scope workspace --role reviewer -o json`                                                                                             |

`get <id> --full` hydrates identity, statuses, diff, and comments in one call, which beats four reads on a PR small enough to hold whole.

`pr.identity` reads the fields from these paths: target is `destination.branch.name`, source branch `source.branch.name`, head SHA `source.commit.hash`, and source repo `source.repository.full_name`, which differs from the destination's on a forked repo.

## Anchors

`comment create` takes the anchor flags directly, and they are the four the contract names:

- `--path <file> --line <n>`: new side, the added or destination side.
- `--path <file> --from-line <n>`: old side; a deleted file takes only this.
- `--path <file> --start-line <a> --end-line <b>`: a range on the new side, which is what a multi-line suggestion takes. `--start-from-line`/`--end-from-line` is the old-side range.
- no `--path`: general.

Bitbucket serves `pr.diff-line` first-class, so every anchor number comes from that command rather than from a local read.

## Threads

Every comment write takes `--comment <id>`, and resolution takes the **top-level** comment's ID, so a thread ID is the ID of the comment that opens the thread. Replies cannot be resolved, reopened, or replied to.

In `comment query` output, each comment holds its anchor in `inline.path`, `inline.to`, and `inline.from`, and `parent.id` when it is a reply. `resolution` is a non-empty object when the thread is resolved; `deleted` and `pending` are flags. A thread is **live** when its opening comment has no `parent`, is not `deleted`, and carries an empty `resolution`.

## Blockers

Bitbucket serves blockers first-class, so a blocker becomes a real task rather than a line in a comment. A task is its own object with its own ID, attached to a thread through `--comment <thread-id>` or standing alone.

A task ID differs from the thread ID it hangs off. `--task` takes the task ID, and `task query` is where a step reads it. A blocker takes both halves: the inline thread carries the finding and the evidence, and the task carries the one-line ask that gates the merge.

`task update --resolve` and `--reopen` duplicate the dedicated verbs; prefer `task resolve` and `task reopen`, which say what they do. `task reopen --pull-request <id> --task <task-id>` revives one closed early.

## Posting

There is no batched review. `comment create --pending` holds a comment as draft feedback, and `twg` has no command that submits it: a pending comment stays invisible until someone finishes the review in the Bitbucket web UI. So post comments outright, one call per finding, unless the user asks for a draft and accepts that hand-off.

## Verdict

`approve`, `request-changes`, and `decline` take no text, so the reason goes in a general comment posted first. `unapprove` and `remove-request-changes` withdraw one.

## Checks

`get <id> --statuses` returns the builds reported on the head under `_statuses`, each with a `name`, a `state` of `SUCCESSFUL`, `FAILED`, `INPROGRESS`, or `STOPPED`, and a `url`. An empty list means no build reports to this PR.

There is no wait flag. A build still `INPROGRESS` is re-read twice at 60 seconds; still pending after that is a result, per `pr`.

A failed build reads its log through the pipeline, not the PR, per the `checks.log` row. `--lines` defaults to 40, and 0 is the whole log. `grep` is what a long log takes: it returns the matching lines alone, so the finding costs a search instead of a context.

If a sandboxed pipeline log request shows a network-blocked message, an S3 hostname, or a log-only HTTP 403 while metadata succeeds, that is a sandbox restriction, not an auth failure.

## Reviewers

`effective-default-reviewer query` lists the reviewers the repo adds on its own, and `get <id>` lists who is already requested under `reviewers`, so the question `pr-open` puts to the user is who joins them. Confirm them on the read-back after create: a default reviewer missing from it is added with `update --add-reviewer`.

## Not served

- **Applying a suggestion**: no command applies one. `pr` describes the manual apply.
- **Checkout**: no command clones or checks out. Fetch the head with `git`, per `pr`.
