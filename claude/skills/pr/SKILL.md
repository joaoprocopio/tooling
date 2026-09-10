---
name: pr
description: "Pull request mechanics shared by pr-open, pr-review, and pr-fix: the forge adapter, the operation contract, identity, drift, checks, and the frontier. Use when opening a change, reviewing one, or working review feedback."
---

# Pull request mechanics

Reference for the mechanics every review step shares. `pr-open`, `pr-review`, and `pr-fix` are the workflows built on it, and each one calls this skill before its first step.

This skill owns the vocabulary those workflows speak: **forge**, **adapter**, **operation**, **source**, **target**, **fixed point**, **pair**, **budget**, **drift**, **check**, and **frontier**. Each has its own section below. [`feedback.md`](feedback.md) owns the rest, **anchor**, **anchor text**, **thread**, **suggestion**, **blocker**, and **verdict**: read it when reviewing a change or working its feedback. Opening a change needs none of it.

Use every word exactly, so one word means one thing across all three workflows, and a finding written in one is legible in the next.

Git carries the change, the diff, and the history. The forge carries the review. Every operation below runs through a **provider adapter**, so a step names the operation and the adapter names the command.

## The forge

Resolve the adapter before step 1 of any workflow:

```bash
git remote get-url origin      # the host names the provider
ls providers/                  # relative to this skill
```

`providers/<name>.md` maps every operation in the contract to that forge's CLI, and declares the operations it cannot serve. Load the file whose hosts match the remote, and say which forge you resolved in your first message.

No adapter for the host means the workflow stops there. Name the host, name the adapters you found, and ask the user to point at the right one or to write it. A missing operation stops the workflow the same way, because a review nobody can read on the forge is not a review.

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

Two operations can be one command. GitHub resolves a thread and lifts the blocker it carries with the same mutation, while Bitbucket serves each against its own id space. The contract keeps them apart so the adapter that separates them can, and an adapter that serves both with one command says so on both rows.

## Identity

A change is a **source** branch merged into a **target**. For a PR that exists, read both from `pr.identity`. The target is a decision, not a default: it is wrong whenever the change **stacks**, sitting on top of another branch still in review. For a branch with no PR yet, settle the target from the workflow's argument, or else from the branch the work was cut from:

```bash
git branch --show-current
git merge-base --fork-point main HEAD     # where the branch left the trunk
git log --oneline --decorate main..HEAD   # what it adds
git rev-parse HEAD                        # the head SHA as a fact, not an assumption
```

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

## The diff budget

Read a diff by parts once it is large enough to fill the context. Take the shape first, then the content:

```bash
git diff <fixed-point>...<head> --stat        # the shape: files and their size
git diff <fixed-point>...<head> -- <path>     # one file, or one group of them
```

Past roughly a thousand changed lines, dispatch per group of files. Give each sub-agent the files it judges, plus the stat for the rest as its context.

## Drift

**Drift** is what a new commit does to an anchor. The head advances, and a line number written against an older head now points at different code. Confirm the anchored line still holds the code the finding describes, re-anchor when it moved, and carry the new number forward. A finding whose subject the current head no longer contains is answered by the head itself.

Measure drift against the head SHA that `pr.identity` returned when the review was written:

```bash
git diff --stat <recorded-head>..HEAD    # empty output means no drift
```

The branch drifts too. Someone else pushes to the source branch while a step is editing it, and the push that ends the step is then a push over their work. Any step that pushes re-reads the remote first:

```bash
git fetch origin <source-branch>
git rev-parse origin/<source-branch>                    # against the SHA the step started from
git log --oneline HEAD..origin/<source-branch>          # what arrived while the step ran
```

Rebase onto a remote that moved. A force-push belongs to the user: name what arrived and let them decide, since forcing over a reviewer's commit destroys work no thread records.

## Writing

Call the Skill tool with `writing-guidelines` before writing any body the forge shows: a description, a comment, or a reply. When the diff touches a file an agent reads, also call the Skill tool with `writing-for-agents`, because agents read the forge too.

Keep the sentences that change a decision. Phrase each ask positively by saying what to do. State what is wrong, cite the evidence, and show the output.

## Checks

Two sources report on a change, and a step reads both.

Local checks come from the repo itself: read the test and lint commands from the package manifest, the task runner, or the CI config. `checks.read` returns the build the forge reports on the head.

A check red for the change is work to redo. A check red for a cause outside the diff is named as such in the general comment, which is what closes a step short of green. A red build reads its log through `checks.log`, which reaches the build system. Take the failing lines alone, since the whole log costs the context the finding needs.

## The frontier

Two workflows put open questions to the user. Call the Skill tool with `grilling` and carry the whole frontier into a single interview, since one round settles the batch. Give every question its evidence, the anchored code or the reviewer's words, plus your recommended answer taken from the code and the commits.

When no user is there to answer, route the decision to a human. `pr-open` opens as a draft with the questions in Notes. `pr-fix` leaves each open finding **discussed**, with the question written into it.
