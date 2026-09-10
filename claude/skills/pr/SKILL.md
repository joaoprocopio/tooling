---
name: pr
description: "Shared pull request mechanics loaded by the pr-open, pr-review, and pr-fix workflows: the forge adapter, the operation contract, identity, drift, checks, the frontier, and the review vocabulary of anchors, threads, suggestions, blockers, and the verdict. Reference only. When the user asks to open, review, or work feedback on a change, tell them to run /pr-open, /pr-review, or /pr-fix."
---

# Pull request mechanics

Reference for the mechanics every review step shares. `pr-open`, `pr-review`, and `pr-fix` are the workflows built on it, and each one calls this skill before its first step.

**Invoked directly?** This skill carries no process. Name the workflow the user wants and stop: `/pr-open` to open a change, `/pr-review` to review one, `/pr-fix` to work its feedback.

This skill owns the vocabulary those workflows speak, each word with its own section below: **forge**, **adapter**, **operation**, **source**, **target**, **fixed point**, **pair**, **budget**, **drift**, **check**, and **frontier**, then **anchor**, **anchor text**, **thread**, **suggestion**, **blocker**, and **verdict**. The sections from **Anchors** to **Verdict** are the review half, which `pr-review` and `pr-fix` reach and `pr-open` skips. Everything above them, and **When a step cannot proceed** below, applies to all three.

Use every word exactly, so one word means one thing across all three workflows.

Git carries the change, the diff, and the history. The forge carries the review. Every operation below runs through a **provider adapter**, so a step names the operation and the adapter names the command.

## The forge

Resolve the adapter before step 1 of any workflow:

```bash
git remote get-url origin      # the host names the provider
```

| Remote host                     | Adapter                  |
| ------------------------------- | ------------------------ |
| `github.com`, GitHub Enterprise | `providers/github.md`    |
| `bitbucket.org`                 | `providers/bitbucket.md` |

Load exactly one file from `providers/`, read from this skill's own directory rather than the working tree.

Say which forge you resolved in your first message.

No adapter for the host stops the workflow. Name the host, name the two adapters above, and ask the user to point at the right one or to write it, per [`providers/AUTHORING.md`](providers/AUTHORING.md). A missing operation stops the workflow the same way.

## The operation contract

Workflows call these by name. An adapter that cannot serve one says so under its `## Not served` heading, alongside the fallback that replaces it.

| Operation         | What it produces                                              |
| ----------------- | ------------------------------------------------------------- |
| `pr.identity`     | target, source branch, head SHA, description                  |
| `pr.files`        | the changed files with their added and removed counts         |
| `pr.diff`         | the delta between the fixed point and the head                |
| `pr.diff-line`    | the line numbers the diff carries for a piece of anchor text  |
| `thread.list`     | every live thread with its ID, anchor, and body               |
| `thread.create`   | a thread anchored to a line                                   |
| `thread.reply`    | a reply under a thread                                        |
| `thread.resolve`  | a thread marked closed                                        |
| `thread.reopen`   | a closed thread live again                                    |
| `blocker.list`    | what gates the merge                                          |
| `blocker.create`  | a finding raised as a gate on the merge                       |
| `blocker.resolve` | a gate lifted                                                 |
| `checks.read`     | the build result on the head                                  |
| `checks.log`      | the log of the failing build                                  |
| `verdict`         | approve, request changes, or decline; the user runs it        |
| `pr.create`       | the change opened for review                                  |
| `pr.update`       | title, description, target, reviewers, or draft state changed |
| `pr.reviewers`    | who the repo adds on its own, and who is already requested    |
| `pr.queue`        | the changes waiting on this user, when no id was given        |

An adapter may map two operations to one command; it then appears on both rows, saying so. GitHub resolves a thread and lifts its blocker with one mutation where Bitbucket serves each against its own id space, so the contract keeps them apart for the forge that separates them.

## Identity

A change is a **source** branch merged into a **target**. For a PR that exists, read both from `pr.identity`. The target is a decision, not a default: it is wrong whenever the change **stacks**, sitting on top of another branch still in review. For a branch with no PR yet, settle the target from the workflow's argument, or else from the branch the work was cut from:

```bash
git branch --show-current                            # empty means detached HEAD
git symbolic-ref --short refs/remotes/origin/HEAD    # the trunk, not an assumption
git merge-base origin/<trunk> HEAD                   # where the branch left the trunk
git log --oneline --decorate origin/<trunk>..HEAD    # what it adds
git rev-parse HEAD                                   # the head SHA as a fact, not an assumption
```

`git symbolic-ref` fails when the remote head is unset. Recover it with `git remote set-head origin --auto`, and take the trunk from the user when that fails too. Use `git merge-base --fork-point` only to refine a base you already have, since it reads the reflog and returns nothing on a fresh clone or a CI checkout.

The **fixed point** is what the diff measures against: the PR's target, or any ref such as `HEAD~1`, a tag, or a SHA when the subject is a bare delta. Confirm it resolves and the diff is non-empty before dispatching work against it.

A **pair** is one change split across two repos. Each side declares its own target, so read `pr.identity` per side and read every side before judging any one of them.

## Checkout

Fetch the head and stay on the branch you are on:

```bash
git fetch origin <source-branch>
git rev-parse origin/<source-branch>    # a SHA other than the recorded head means it moved
git diff origin/<target>...origin/<source-branch>
```

Fetching is the first command of any step that reads the diff. Only a step that edits and pushes the branch checks it out, and it does so at the start of that step.

Because the workflows stay off the source branch, `HEAD` is whatever branch the user is sitting on. Every command that measures the change names `origin/<source-branch>` explicitly.

## The diff budget

Read a diff by parts once the whole patch costs more context than the findings it feeds. Take the shape first, then the content:

```bash
git diff <fixed-point>...<head> --stat        # the shape: files and their size
git diff <fixed-point>...<head> -- <path>     # one file, or one group of them
```

Past 1000 changed lines, dispatch per group: one sub-agent per 400 changed lines, grouped by top-level directory, capped at six. Give each one the diff for its own files plus the `--stat` for the rest as its context.

## Drift

**Drift** is what a new commit does to an anchor. The head advances, and a line number written against an older head now points at different code. Confirm the anchored line still holds the code the finding describes, re-anchor when it moved, and carry the new number forward. A finding whose subject the current head no longer contains needs no thread.

Measure drift against the head SHA that `pr.identity` returned when the review was written:

```bash
git fetch origin <source-branch>
git diff --stat <recorded-head>..origin/<source-branch>    # empty output means no drift
```

The branch drifts too. Someone else pushes to the source branch while a step is editing it, and the push that ends the step is then a push over their work. Any step that pushes re-reads the remote first, against the SHA it started from:

```bash
git fetch origin <source-branch>
git rev-parse origin/<source-branch>
git log --oneline <sha-the-step-started-from>..origin/<source-branch>    # what arrived while the step ran
```

Rebase onto a remote that moved. A force-push belongs to the user: name what arrived and let them decide, since forcing over a reviewer's commit destroys work no thread records.

## Writing

Call the Skill tool with `writing-guidelines` once, before the first body the forge shows, and let it govern every description, comment, and reply in the run. When the diff touches a file an agent reads, `CLAUDE.md`, `AGENTS.md`, or a skill, also call the Skill tool with `writing-for-agents`.

Keep the sentences that change a decision. Phrase each ask positively by saying what to do. State what is wrong, cite the evidence, and show the output.

## Checks

Two sources report on a change, and a step reads both.

Local checks come from the repo itself: read the test and lint commands from the package manifest, the task runner, or the CI config. `checks.read` returns the build the forge reports on the head.

A check red for the change is work to redo. A check red for a cause outside the diff is named as such in the general comment, which is what closes a step short of green. A red build reads its log through `checks.log`, which reaches the build system. Take the failing lines alone, since the whole log costs the context the finding needs.

## The frontier

Two workflows put open questions to the user. Call the Skill tool with `grilling` and carry the whole frontier into a single interview, since one round settles the batch. Give every question its evidence, the anchored code or the reviewer's words, plus your recommended answer taken from the code and the commits.

## Anchors

An **anchor** is a file and a line, in one of four shapes:

- **New side**: a line the diff adds, which is what a suggestion takes
- **Old side**: a line the diff removes, which is all a deleted file takes
- **Range**: several lines on the new side, for a suggestion replacing more than one
- **General**: no anchor at all, which is where the summary and the merge blockers go

An anchor holds only on a line the diff carries, and its number comes from `pr.diff-line`. **Anchor text** is what `pr.diff-line` takes: the distinctive text of the line, appearing once in the file, with the file path. Text that matches more than once has no anchor: narrow it, or take the finding to a general comment. A number read off the local file is the wrong number whenever the head moves or the hunk shifts.

A finding about a line outside every hunk goes in a general comment naming the file and line in its text. A rejected post is the server refusing the anchor: re-run `pr.diff-line` and re-anchor.

## Threads

A thread is one subject: the finding, its evidence, and the replies under it. A thread is **live** while the forge reports it unresolved, and `thread.list` is what the fix loop reads.

Two rules hold on every forge:

- **A thread ID is the ID of the comment that opens it.** Replies hang off that ID, and resolution takes it.
- **One subject per thread.** A second subject is a second `thread.create`, so the author can resolve each one on its own.

## Suggestions

Write a suggestion by fencing the replacement lines in the body, which gives the author a one-click apply on every forge that renders it:

````text
```suggestion
const timeout = 30_000
```
````

The fence replaces the anchored lines, so anchor it to exactly the lines it replaces and keep the block to what changes.

Apply one that came the other way by editing the anchored lines yourself: read the anchor, confirm those lines still hold the code the suggestion replaces, and put the fenced block in their place.

## Blockers

A **blocker** is a finding that gates the merge. It takes both halves: the thread carries the evidence, and one line names the change that unblocks it. An adapter with first-class tasks raises a task against the thread; an adapter without them raises the merge block through its verdict. `blocker.list` is what a later step closes each one against.

## Verdict

The verdict is **approve**, **request changes**, or **decline**, and it is the reviewer's terminal act. It belongs to the user: state the verdict you would give and let the user run the command.

## When a step cannot proceed

Each case below stops the step it belongs to. Report the state and what you need, rather than working around it.

- **No user to answer.** `pr-open` opens as a draft with the questions in Notes. `pr-fix` leaves each open finding **discussed**, with the question written into it. A `pr.queue` holding more than one entry stops the workflow instead: report the queue and exit, since picking the subject is the user's.
- **No PR for the subject.** A PR id that returns nothing, or a branch with no PR, stops the step. Name what you looked for, and offer `/pr-open` when the branch has commits the target does not.
- **A dirty tree before a checkout.** Report the files from `git status --short` and stop. Committing or stashing another agent's uncommitted work belongs to the user.
- **Detached HEAD.** `git branch --show-current` returns empty. Name the SHA and ask which branch the work belongs to.
- **A rejected push.** Re-read the remote per **Drift** and rebase. Never `--force`.
- **A rate limit.** Stop the posting loop, name how many findings landed and which remain, and let the user resume. Batch the posts per the adapter to avoid it.
- **Checks still pending.** Wait once, with a ceiling: GitHub takes `gh pr checks --watch`, Bitbucket polls twice at 60 seconds. Still pending after that is a result: report it and close the step short of green.
