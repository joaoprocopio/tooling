---
name: pr
description: "Pull request mechanics shared by every review step: the forge adapter, the operation contract, the fixed point, the diff budget, anchors, drift, threads, suggestions, blockers, checks, and the verdict. Use when reviewing a change, opening one, or working review feedback."
---

# Pull request mechanics

Reference for the mechanics every review step shares. `pr-open`, `pr-review`, and `pr-fix` are the workflows built on it, and each one calls this skill before its first step.

This skill owns the vocabulary those workflows speak: **forge**, **adapter**, **operation**, **fixed point**, **pair**, **budget**, **anchor**, **drift**, **thread**, **suggestion**, **blocker**, **check**, **frontier**, and **verdict**. Each has its own section below. Use them exactly, so one word means one thing across all three workflows, and so a finding written in one is legible in the next.

The vocabulary is the forge's, and so is the storage: git carries the change, the diff, and the history, while the forge carries the review. Every operation below runs through a **provider adapter**, so a step names the operation and the adapter names the command.

## The forge

Resolve the adapter before step 1 of any workflow:

```bash
git remote get-url origin      # the host names the provider
ls providers/                  # relative to this skill
```

`providers/<name>.md` maps every operation in the contract to that forge's CLI, and declares the operations it cannot serve. Load the file whose hosts match the remote, and say which forge you resolved in your first message.

No adapter for the host means the workflow stops there. Name the host, name the adapters you found, and ask the user to point at the right one or to write it. Never substitute git for a missing operation: a review nobody can read on the forge is not a review.

## The operation contract

Workflows call these by name. An adapter that cannot serve one says so under its `## Not served` heading, alongside the fallback that replaces it.

| Operation         | What it produces                                              |
| ----------------- | ------------------------------------------------------------- |
| `pr.identity`     | target, source branch, head SHA, description                  |
| `pr.files`        | the changed files with their added and removed counts         |
| `pr.diff`         | the delta between the fixed point and the head                |
| `pr.diff-line`    | the line numbers the diff carries for a piece of text         |
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
| `verdict`         | approve, request changes, or decline                          |
| `pr.create`       | the change opened for review                                  |
| `pr.update`       | title, description, target, reviewers, or draft state changed |
| `pr.reviewers`    | who the repo adds on its own, and who is already requested    |
| `pr.queue`        | the changes waiting on this user, when no id was given        |

Two operations can be one command. GitHub resolves a thread and lifts the blocker it carries with the same mutation, while Bitbucket serves each against its own id space. The contract keeps them apart so the adapter that separates them can, and an adapter that serves both with one command says so on both rows.

## Identity

A change is a **source** branch merged into a **target**. For a PR that exists, read both from `pr.identity` rather than assuming them. The target is a decision, not a default: it is wrong whenever the change **stacks**, sitting on top of another branch still in review.

For a branch with no PR yet, git is the source:

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

Fetching is the first command of any step that reads the diff. A step that edits and pushes the branch checks it out in its own step.

## The diff budget

Read a diff by parts once it is large enough to fill the context. Take the shape first, then the content:

```bash
git diff <fixed-point>...<head> --stat        # the shape: files and their size
git diff <fixed-point>...<head> -- <path>     # one file, or one group of them
```

Past roughly a thousand changed lines, dispatch per group of files instead of once over the whole delta. Give each sub-agent the files it judges, plus the stat for the rest as its context.

## Anchors

An **anchor** is a file and a line, in one of four shapes:

- **New side**: a line the diff adds, which is what a suggestion takes
- **Old side**: a line the diff removes, which is all a deleted file takes
- **Range**: several lines on the new side, for a suggestion replacing more than one
- **General**: no anchor at all, which is where the summary and the merge blockers go

An anchor holds only on a line the diff carries. Take every line number from `pr.diff-line`, giving it the distinctive text of the line and the file path, rather than reading a number off the local file. Local numbers and diff numbers disagree whenever the head moves or the hunk shifts.

A finding about a line outside every hunk goes in a general comment naming the file and line in its text. A rejected post is the server refusing the anchor: re-run `pr.diff-line` and re-anchor rather than retrying the same number.

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

## Threads

A thread is one subject: the finding, its evidence, and the replies under it. A thread is **live** while the forge reports it unresolved, and `thread.list` is what the fix loop reads.

Two rules hold on every forge:

- **A thread ID is the ID of the comment that opens it.** Replies hang off that ID, and resolution takes it.
- **One subject per thread.** A second subject is a second `thread.create`, so the author can resolve each one on its own.

## Writing

Call the Skill tool with `writing-guidelines` before writing any comment body, so the prose stays active and concise. When the diff touches a file an agent reads, also call the Skill tool with `writing-for-agents`, because agents read review comments too: keep the sentences that change a decision, and phrase the ask positively by saying what to do.

State what is wrong, cite the evidence, and show the output.

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

## Checks

Two sources report on a change, and a step reads both.

Local checks come from the repo itself: read the test and lint commands from the package manifest, the task runner, or the CI config, rather than guessing them. `checks.read` returns the build the forge reports on the head.

A check red for the change is work to redo. A check red for a cause outside the diff is named as such in the general comment, which is what closes a step short of green. A red build reads its log through `checks.log`, which reaches the build system rather than the PR. Take the failing lines alone, since the whole log costs the context the finding needs.

## The frontier

Two workflows put open questions to the user. Call the Skill tool with `grilling` and carry the whole frontier into a single interview, since it asks a whole frontier per round and one pass settles the batch. Give every question its evidence, the anchored code or the reviewer's words, plus your recommended answer taken from the code and the commits.

When no user is there to answer, route the decision to a human instead of picking silently: open as a draft with the questions in Notes, or leave the finding open with the question written into it.

## Verdict

The verdict is **approve**, **request changes**, or **decline**, and it is the reviewer's terminal act. It belongs to the user: state the verdict you would give and let the user run the command.
