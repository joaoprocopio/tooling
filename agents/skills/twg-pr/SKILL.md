---
name: twg-pr
description: "Bitbucket pull request mechanics with twg: identity, checkout, anchors, drift, threads, replies, suggestions, resolution, tasks, checks, and verdict. Use when reading or writing PR comments, or when another skill needs the review vocabulary."
---

Reference for the mechanics every `twg bb prs` review command shares. The `twg` skill carries invocation, the auth guard, and the output envelope, and `twg help describe "bb pull-requests <command>"` carries the exact contract for anything below. `twg` reads `-w <workspace>` and `-r <repo>` from the git remote of the working directory. Pass both explicitly whenever the command runs outside the PR's checkout, which every command on a pair does.

Every command takes `-o json`. A step that parses output asks for JSON and writes it to a stable path with `--output-file <path>`, then reads that file, rather than parsing the human table or the YAML envelope.

## Identity

A PR is an `<id>` in a `<workspace>/<repo>`. `twg bb prs get <id> -o json` returns the title, state, author, description, reviewers, and the declared **target**, the branch it merges into:

| Fact | Path |
|------|------|
| target | `destination.branch.name` |
| source branch | `source.branch.name` |
| head SHA | `source.commit.hash` |
| source repo | `source.repository.full_name`, which differs from the destination's on a fork |

A **pair** is the set of PRs passed together, one change split across repos. Each PR in a pair declares its own target, so read the target from each PR rather than copying it from the sibling. Read every PR in a pair before judging any one of them.

## Checkout

`twg` has no checkout command, so fetch the head from the identity above and stay on the branch you are on:

```bash
git fetch origin <source-branch>
git rev-parse origin/<source-branch>        # equals source.commit.hash, else the head moved since the read
```

A fork adds the source repo as a remote first and fetches from it. Fetching is the first move of any skill that reads the diff. `git diff origin/<target>...origin/<source-branch>` is then the delta, and `twg bb prs diff <id>` is the same delta as the server sees it. A skill that edits and pushes the branch checks it out itself, in its own step.

## Anchors

An **anchor** is a repo, a file, and a line:

- `--path <file> --line <line>` anchors to the new file, the added or destination side.
- `--path <file> --from-line <line>` anchors to the old file, the removed or source side, and a deleted file takes only this.
- `--start-line <a> --end-line <b>` anchors a range on the new side, which is what a suggestion replacing several lines takes.
- No `--path` makes the comment **general**: activity-level, carrying no anchor, which is where the summary and the merge blockers go.

Bitbucket accepts an anchor only on a line the diff carries. `twg bb prs diff-line <id> --text "<distinctive text>" --path <file>` returns the line numbers the current diff holds for that text, so take every anchor from it rather than from the local file. A finding about a line outside every hunk goes in a general comment that names the file and line in its text. A rejected post is the server refusing the anchor, so re-run `diff-line` and re-anchor rather than retrying the same number.

## Drift

**Drift** is what a push does to an anchor. The head advances, and a line number written against an older head now points at different code. Confirm the anchored line still holds the code the comment describes, re-anchor the thread when it moved, and carry the new number forward. A thread whose subject the current head no longer contains is answered by the head itself.

## Threads

A thread is its top-level comment, with replies under it. Every comment command takes `--comment <id>`, and resolution takes the top-level ID, so a **thread ID** is the ID of the comment that opens the thread. Replies cannot be resolved, reopened, or replied to.

```bash
twg bb prs comment query <id> -o json --output-file <path>
```

Each comment in the list holds its anchor in `inline.path`, `inline.to`, and `inline.from`, and `parent.id` when it is a reply. `resolution` is a non-empty object when the thread is resolved, and `deleted` and `pending` are flags. A thread is **live** when its opening comment has no `parent`, is not `deleted`, and carries an empty `resolution`.

## Writing

```bash
twg bb prs comment create --pull-request <id> --text "$(cat <file.md>)"                        # general
twg bb prs comment create --pull-request <id> --path <file> --line <line> --text "$(cat <file.md>)"  # inline
twg bb prs comment create --pull-request <id> --reply-to <thread-id> --text "$(cat <file.md>)"      # reply
```

Call the Skill tool for `writing-guidelines` before writing any comment body: active, concise, filler cut.

`--pending` holds a comment as draft review feedback, and `twg` has no command that submits it: a pending comment stays invisible until someone finishes the review in the Bitbucket web UI. Post comments outright unless the user asks for a draft and accepts that hand-off.

## Suggestions

Write a suggestion by fencing the replacement lines in the comment body, which gives the author a one-click apply:

````text
```suggestion
const timeout = 30_000
```
````

The fence replaces the anchored lines, so anchor it to exactly the lines it replaces, a single `--line` or a `--start-line`/`--end-line` range, and keep the block to what changes.

`twg` has no command that applies a suggestion. Apply one that came the other way by editing the anchored lines yourself. Read the thread's `inline` anchor, confirm those lines still hold the code the suggestion replaces, and put the fenced block in their place.

## Resolution

```bash
twg bb prs comment resolve --pull-request <id> --comment <thread-id>
twg bb prs comment reopen  --pull-request <id> --comment <thread-id>
```

Resolve a thread that is fixed or answered. Reopen one that closed early, when a reply revives the question or the fix turns out to miss it.

## Tasks

A **task** is a blocker the PR carries as unfinished work. It is its own object with its own ID, attached to a thread through `--comment <thread-id>` or standing alone. `twg bb prs task query <id>` maps task IDs to the threads that carry them. Read that list whenever a step needs a task ID.

```bash
twg bb prs task create  --pull-request <id> --text "..." [--comment <thread-id>]
twg bb prs task query   <id> -o json
twg bb prs task resolve --pull-request <id> --task <task-id>
twg bb prs task reopen  --pull-request <id> --task <task-id>
```

A blocker takes both halves: the inline thread carries the finding and the evidence, and the task attached to it carries the one-line ask that gates the merge.

## Checks

`twg bb prs get <id> --statuses -o json` returns the builds reported on the head under `_statuses`, each with a `name`, a `state` of `SUCCESSFUL`, `FAILED`, `INPROGRESS`, or `STOPPED`, and a `url`. An empty list means no build reports to this PR. There is no wait flag: a build still `INPROGRESS` is re-read after a pause sized to the pipeline's usual run.

A failed build reads its log through the pipeline, not the PR:

```bash
twg bb pipeline latest-failure --branch <source-branch>          # the failed step's log tail
twg bb pipeline get --pipeline <n> --logs --failed-steps          # more of the same build
```

## Verdict

`twg bb prs approve <id>` records approval as the authenticated user. `twg bb prs request-changes <id>` blocks the merge until withdrawn, and `twg bb prs decline <id>` closes the PR against the change. None of the three takes a message, so the reason goes in a general comment posted first. All three are the reviewer's terminal act, and all three belong to the user: state the verdict you would give and let the user run the command.
