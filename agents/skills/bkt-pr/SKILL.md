---
name: bkt-pr
description: "Bitbucket pull request review mechanics with bkt: anchors, threads, replies, suggestions, resolution, tasks, and checks. Use when reading or writing PR comments, or when another skill needs the review vocabulary."
---

Reference for the mechanics every `bkt` review command shares. The `bkt` skill carries the wider CLI, including installation and context setup. Pass `--repo <slug>` on every command below, plus `--project` (Data Center) or `--workspace` (Cloud) when the active context names neither.

## Identity

A PR is an `<id>` in a `<slug>`. `bkt pr view <id> --json` returns the description, the declared **target** (the branch it merges into, which differs between repos in a pair), and the **head** (the SHA under review). `git diff <target>...HEAD` is the delta, and `bkt pr diff <id>` is the same delta as the server sees it.

The head advances with every push, so a comment written against an older head carries a line number that has aged. Re-read the anchor before trusting the number.

## Anchors

An **anchor** is a repo, a file, and a line:

- `--file <path> --to-line <line>` anchors to the new file, the added or destination side.
- `--file <path> --from-line <line>` anchors to the old file, the removed or source side, and a deleted file takes only this.
- No `--file` makes the comment **general**: activity-level, carrying no anchor, which is where the summary and the merge blockers go.

## Threads

A thread is its top-level comment, with replies hanging off it. Every state command takes the **thread ID**, because a reply cannot be resolved, reopened, or replied to.

```bash
bkt pr comments <id> --details            # thread IDs, anchors, resolution, task status
bkt pr comments <id> --state unresolved   # Cloud only
```

Data Center leaves resolution status out of the API, so `--state` is Cloud-only and the replies on a thread are what tell you it is still live.

## Writing

```bash
bkt pr comment <id> --text "$(cat <file.md>)"                                    # general
bkt pr comment <id> --file <path> --to-line <line> --text "$(cat <file.md>)"     # inline
bkt pr comment <id> --parent <thread-id> --text "$(cat <file.md>)"               # reply
```

`--pending` holds a comment as draft review feedback until you submit it.

## Suggestions

Write a suggestion by fencing the replacement lines in the comment body, which gives the author a one-click apply:

````text
```suggestion
const timeout = 30_000
```
````

The fence replaces the anchored lines, so anchor it to exactly the lines it replaces and keep the block to what changes.

Apply one that came the other way with `bkt pr suggestion <id> <thread-id> <suggestion-id>`, reading it first with `--preview`. Data Center only; on Cloud, copy the block into the edit yourself.

## Resolution

```bash
bkt pr comments resolve <id> <thread-id>
bkt pr comments reopen <id> <thread-id>
```

Resolve a thread that is fixed or answered. Reopen one that closed early, when a reply revives the question or the fix turns out to miss it.

## Tasks

A **task** is a blocker the PR carries as unfinished work. Data Center models it as a blocker comment, so its ID can differ from the thread ID, and `bkt pr task list` maps the two.

```bash
bkt pr task create <id> --text "..."
bkt pr task list <id>
bkt pr task complete <id> <task-id>
bkt pr task reopen <id> <task-id>
```

## Checks

`bkt pr checks <id>` reports the build on the head, and `--wait` polls to completion. Its exit codes are 0 for passed, 1 for a failed build, and 8 for a timeout with builds still pending.
