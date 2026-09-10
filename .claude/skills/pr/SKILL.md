---
name: pr
description: "Pull request review mechanics, independent of any forge: the fixed point, anchors, drift, the review file, threads, suggestions, blockers, checks, and verdict. Use when reviewing a change or working review feedback, or when another skill needs the review vocabulary."
---

Reference for the mechanics every review step shares. `pr-open`, `pr-review`, and `pr-fix` are the workflows built on it, and each calls this skill first.

The vocabulary here is the forge's, but nothing here needs a forge. Git carries the change, the diff, and the history; a file carries the review. A provider adapter, when one exists, replaces the file with the server's own threads — the workflows never change, because they only ever name the operation.

## Detached and attached

**Detached** is the default and needs nothing but `git`: the review lives in a file, findings are reported rather than posted, and fixes land as commits. **Attached** means a provider adapter is loaded and the same operations write to the forge instead.

Resolve which one applies before step 1 of any workflow:

```bash
git remote get-url origin      # the host names the provider
ls providers/                  # relative to this skill; empty means detached
```

`providers/<name>.md` maps every operation in the contract below to that forge's CLI, and declares which operations it cannot serve. No file, or no matching host, means detached — say so once, in the first message, so the user knows the review will not be posted.

## The operation contract

The workflows call these by name. The **detached** column is the implementation when no adapter is loaded, and it is complete: no step is skipped for want of a forge.

| Operation        | What it must produce                               | Detached                                           |
| ---------------- | -------------------------------------------------- | -------------------------------------------------- |
| `pr.identity`    | target, source branch, head SHA, description       | `git` refs plus the review file's front matter     |
| `pr.diff`        | the delta between fixed point and head             | `git diff <base>...<head>`                         |
| `pr.diff-line`   | the line numbers the diff carries for a text       | the anchor recipe below                            |
| `thread.list`    | every live thread with ID, anchor, body            | the review file's open findings                    |
| `thread.create`  | a thread anchored to a line                        | a finding section in the review file               |
| `thread.reply`   | a reply under a thread                             | a reply block under that section                   |
| `thread.resolve` | a thread marked closed                             | the section's `state` line                         |
| `blocker.list`   | what gates the merge                               | findings marked `blocker: yes`                     |
| `checks.read`    | the build result on the head                       | the repo's own checks, run locally                 |
| `verdict`        | approve, request changes, decline                  | the verdict line in the report                     |
| `pr.create`      | the change opened for review                       | `git push`, then the create URL handed to the user |
| `pr.update`      | title, description, reviewers, draft state changed | the description file rewritten on disk             |

An adapter that cannot serve an operation says so, and the operation falls back to its detached form for that run. It never silently does nothing.

## Identity

A change is a **source** branch merged into a **target**. The target is a decision, not a default: it is wrong whenever the change **stacks**, sitting on top of another branch still in review.

```bash
git branch --show-current
git merge-base --fork-point main HEAD     # where the branch left the trunk
git log --oneline --decorate main..HEAD   # what it adds
git rev-parse HEAD                        # the head SHA, a fact rather than an assumption
```

The **fixed point** is what the diff is measured against: the target for a branch under review, or any ref — `HEAD~1`, a tag, a SHA — when the subject is a bare delta. Confirm it resolves and the diff is non-empty before dispatching any work against it.

A **pair** is one change split across repos. Each side declares its own target, so read the target from each rather than copying it from the sibling, and read every side before judging any one of them.

## Checkout

Fetch the head and stay on the branch you are on:

```bash
git fetch origin <source-branch>
git rev-parse origin/<source-branch>    # differs from the recorded head means it moved since the read
git diff origin/<target>...origin/<source-branch>
```

Fetching is the first move of any step that reads the diff. A step that edits and pushes the branch checks it out itself, in its own step.

## Anchors

An **anchor** is a file and a line:

- a line on the **new** side, the added or destination side, which is what a suggestion takes.
- a line on the **old** side, the removed or source side, which is all a deleted file takes.
- a **range** on the new side, for a suggestion replacing several lines.
- **general**, carrying no anchor, which is where the summary and the merge blockers go.

An anchor holds only on a line the diff carries. Take every line number from the diff rather than from the local file:

```bash
# new-side line numbers for every added line in <file>
git diff -U0 <base>...HEAD -- <file> \
  | awk '/^\+\+\+/{next} /^@@/{ n=$3; sub(/^\+/,"",n); split(n,p,","); ln=p[1]+0; next } /^\+/{ print ln"\t"substr($0,2); ln++ }'

# old-side line numbers for every removed line
git diff -U0 <base>...HEAD -- <file> \
  | awk '/^---/{next} /^@@/{ n=$2; sub(/^-/,"",n); split(n,p,","); ln=p[1]+0; next } /^-/{ print ln"\t"substr($0,2); ln++ }'
```

A finding about a line outside every hunk goes in a general comment that names the file and line in its text. Attached, a rejected post is the server refusing the anchor: re-read the diff and re-anchor rather than retrying the same number.

## Drift

**Drift** is what a new commit does to an anchor. The head advances, and a line number written against an older head now points at different code. Confirm the anchored line still holds the code the finding describes, re-anchor when it moved, and carry the new number forward. A finding whose subject the current head no longer contains is answered by the head itself.

Detached, the review file's `head:` is what drift is measured against:

```bash
git diff --stat <recorded-head>..HEAD    # empty means no drift
```

## The review file

Detached, this file is the thread store. It is the deliverable of `pr-review` and the subject of `pr-fix`, and it is what makes the loop close without a forge.

Write it to `.claude/reviews/<branch>-<head-short>.md`. It is an artifact, not source: gitignore that directory unless the team decides to track reviews on purpose. Say where it landed.

```markdown
---
base: <fixed-point SHA>
head: <SHA reviewed>
branch: <source branch>
generated: <ISO date>
---

# Review — <one line naming the change>

<The general comment: what the change delivers, what blocks the merge, the count per axis.>

## F1 · src/api/client.ts:42 · standards
state: open
blocker: yes

What is wrong, the evidence from the file or the spec, and the output.
```

One `##` section per finding. The heading carries the ID, the anchor, and the axis; `state` and `blocker` are each one word on their own line, so a later step can update one without rewriting the section.

`state` is one of **open**, **fixed**, **answered**, **deferred**, or **discussed** — the five the fix loop puts a finding in. A finding is **live** while its state is `open` or `discussed`.

A reply is a `> ` block appended to the section, prefixed with who wrote it. Attached, the same text goes to `thread.reply` instead.

## Writing

Call the Skill tool for `writing-guidelines` before writing any comment body: active, concise, filler cut. `writing-for-agents` governs the cut when the diff touches a file an agent reads, because agents read review comments too: keep the sentences that change a decision, and phrase the ask positively, saying what to do.

State what is wrong, cite the evidence, show the output. One subject per comment.

## Suggestions

Write a suggestion by fencing the replacement lines in the body, which gives the author a one-click apply on every forge that renders it and a copyable block everywhere else:

````text
```suggestion
const timeout = 30_000
```
````

The fence replaces the anchored lines, so anchor it to exactly the lines it replaces and keep the block to what changes.

Apply one that came the other way by editing the anchored lines yourself: read the anchor, confirm those lines still hold the code the suggestion replaces, and put the fenced block in their place.

## Blockers

A **blocker** is a finding that gates the merge. It takes both halves: the finding carries the evidence, and one line names the change that unblocks it. Detached, that is `blocker: yes` plus the general comment listing them. Attached, an adapter with first-class tasks raises one against the thread; an adapter without them raises the merge block through its verdict instead.

## Local checks

Every workflow runs the repo's own checks, reading the command from the environment rather than guessing: the test and lint scripts in the package manifest, the task runner, or the CI config.

A check red for the change is work to redo. A check red for a cause outside the diff is named as such, in the general comment, which is what closes a step short of green. Detached, this is the whole of `checks.read`; attached, an adapter adds the build the forge reports on the head, and a red build reads its log through the pipeline rather than through the PR.

## The frontier

Two workflows put open questions to the user, and both do it the same way. Call the Skill tool for `grilling`, carrying the whole frontier into a single interview: it asks a whole frontier per round, so one pass settles the batch. Give every question the evidence — the anchored code, the reviewer's words — and your recommended answer, taken from the code and the commits.

When no user is there to answer, never pick silently. Route the decision to a human by the workflow's own fallback: open as draft with the questions in Notes, or leave the finding `discussed` with the question written into it.

## Verdict

The verdict is **approve**, **request changes**, or **decline**, and it is the reviewer's terminal act. Detached, it closes the report. Attached, it belongs to the user: state the verdict you would give and let the user run the command.
