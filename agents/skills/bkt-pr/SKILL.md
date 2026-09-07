---
name: bkt-pr
description: "Bitbucket pull request mechanics with bkt: checkout, anchors, drift, threads, replies, suggestions, resolution, tasks, checks, and approval. Use when reading or writing PR comments, or when another skill needs the review vocabulary."
---

Reference for the mechanics every `bkt` review command shares. The `bkt` skill carries installation and context setup, and [`bkt/rules/pr.md`](../bkt/rules/pr.md) carries the full flag list for anything below. Pass `--repo <slug>` on every command, plus `--project` (Data Center) or `--workspace` (Cloud) when the active context names neither repo nor owner.

Every command inherits `--json` and `--jq`, so a step that parses output asks for JSON rather than reading the human table.

## Identity

A PR is an `<id>` in a `<slug>`. `bkt pr view <id> --json` returns the title, state, author, description, reviewers, and the declared **target**, the branch it merges into.

A **pair** is the set of PRs passed together, one change split across repos. Each PR in a pair declares its own target, and targets usually differ between the repos. Read every PR in a pair before judging any one of them.

## Checkout

`bkt pr view` does not return a commit, so take the **head**, the SHA under review, from git after checking the PR out:

```bash
bkt pr checkout <id>     # fetches the PR head into local branch pr/<id>
git rev-parse HEAD       # the head SHA under review
```

Checkout is the first move of any skill that reads the diff or writes to the branch: it fetches the head ref on Data Center, resolves the source branch on Cloud, and adds a remote for a Cloud fork. `git diff <target>...HEAD` is then the delta, and `bkt pr diff <id>` is the same delta as the server sees it.

## Anchors

An **anchor** is a repo, a file, and a line:

- `--file <path> --to-line <line>` anchors to the new file, the added or destination side.
- `--file <path> --from-line <line>` anchors to the old file, the removed or source side, and a deleted file takes only this.
- No `--file` makes the comment **general**: activity-level, carrying no anchor, which is where the summary and the merge blockers go.

Bitbucket accepts an anchor only on a line the diff carries. Read `bkt pr diff <id>` and anchor inside a hunk; a finding about a line outside every hunk goes in a general comment that names the file and line in its text. A rejected post is the server refusing the anchor, so re-read the hunk and re-anchor rather than retrying the same line.

## Drift

**Drift** is what a push does to an anchor. The head advances, and a line number written against an older head now points at different code. Confirm the anchored line still holds the code the comment describes, re-anchor the thread when it moved, and carry the new number forward. A thread whose subject the current head no longer contains is answered by the head itself.

## Threads

A thread is its top-level comment, with replies hanging off it. `bkt` names the argument `<comment-id>` and takes the top-level ID, so a **thread ID** is the ID of the comment that opens the thread. Replies cannot be resolved, reopened, or replied to.

```bash
bkt pr comments <id> --details            # thread IDs, anchors, resolution, task status
bkt pr comments <id> --state unresolved   # Cloud only
```

Data Center leaves resolution status out of the API, so `--state` is Cloud-only. On Data Center a thread counts as **live** when no reply on it settles the point it raises, and its task, when it has one, is still open in `bkt pr task list`.

## Writing

```bash
bkt pr comment <id> --text "$(cat <file.md>)"                                    # general
bkt pr comment <id> --file <path> --to-line <line> --text "$(cat <file.md>)"     # inline
bkt pr comment <id> --parent <thread-id> --text "$(cat <file.md>)"               # reply
```

Call the Skill tool for `writing-guidelines` before writing any comment body: active, concise, filler cut.

`--pending` holds a comment as draft review feedback, and `bkt` has no command that submits it: a pending comment stays invisible until someone submits the review in the Bitbucket web UI. Post comments outright unless the user asks for a draft and accepts that hand-off.

## Suggestions

Write a suggestion by fencing the replacement lines in the comment body, which gives the author a one-click apply:

````text
```suggestion
const timeout = 30_000
```
````

The fence replaces the anchored lines, so anchor it to exactly the lines it replaces and keep the block to what changes.

Apply one that came the other way with `bkt pr suggestion <id> <comment-id> <suggestion-id>`, where `<comment-id>` is the thread holding the suggestion and `<suggestion-id>` indexes the fenced blocks within that comment. Read it with `--preview` first, which confirms the index and shows the replacement, because the suggestion's own lines drift. Data Center only; on Cloud, copy the block into the edit yourself.

## Resolution

```bash
bkt pr comments resolve <id> <thread-id>
bkt pr comments reopen <id> <thread-id>
```

Resolve a thread that is fixed or answered. Reopen one that closed early, when a reply revives the question or the fix turns out to miss it.

## Tasks

A **task** is a blocker the PR carries as unfinished work. Data Center models it as a blocker comment, so its ID differs from the thread ID and `bkt pr task list <id>` maps the two. Read that list whenever a step needs a task ID; `--details` on `bkt pr comments` reports task status, not the ID.

```bash
bkt pr task create <id> --text "..."
bkt pr task list <id>
bkt pr task complete <id> <task-id>
bkt pr task reopen <id> <task-id>
```

Because a Data Center task is itself a comment, a blocker raised as a task is already posted: give the detail to the task text and leave the inline thread to findings that block nothing.

## Checks

`bkt pr checks <id>` reports the build on the head. `--wait` polls to completion with backoff, `--fail-fast` exits on the first failure and requires `--wait`, and `--timeout` bounds the wait, which otherwise runs until every build settles.

In `--wait` mode the exit codes are 0 for passed, 1 for a failed build, and 8 for a timeout with builds still pending. Without `--wait` the command reports current status and these codes do not apply.

## Verdict

`bkt pr approve <id>` records approval as the authenticated user, and `bkt pr decline <id> --comment "..."` closes the PR against the change. Both are the reviewer's terminal act, and both belong to the user: state the verdict you would give and let the user run the command.
