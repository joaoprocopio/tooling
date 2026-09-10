---
name: pr-review
description: "Review a change against a fixed point along two axes, and return findings anchored to the line."
argument-hint: "<ref>, a PR id, or nothing"
disable-model-invocation: true
---

Review a change along two axes: Standards and Spec. Call the Skill tool for `pr` first, which carries the fixed point, checkout, anchors, drift, the review file, suggestions, blockers, and the voice every step below uses. `pr-fix` is the other half of the loop: it works the findings this skill writes.

## The fixed point

The skill's argument is what the diff is measured against, and it decides every step below:

- **A ref**: `HEAD~1`, a tag, a SHA, or a branch. The review covers that delta.
- **A PR id, or a pair**: the fixed point is each PR's declared target. This needs an adapter; with none loaded, resolve the target as a branch and review the delta against it.
- **Nothing**: ask which before measuring.

Confirm the ref resolves and the diff is non-empty before dispatching the axes, because a bad ref is cheaper to catch here than inside two sub-agents.

## The bar

Post a finding that changes the code or changes the merge decision. A finding that changes neither belongs in the report alone, where it costs the author a read instead of a thread. `karpathy-guidelines` sets what counts as a finding at all.

## Process

### 1. Resolve the subject (`pr`)

Resolve detached or attached, and say which in the first message. Then fetch and check out, so the diff the axes measure is the head that will be reported and the head SHA is a fact from git.

**Done when** the fixed point, the source branch, the head SHA, and the description are known for every side of the subject, and a local branch holds each one.

### 2. Measure both axes (`code-review`)

Dispatch both axes in parallel, in a single message. Run the two axes once per side of a pair, giving each run the other sides as context, so a finding can name the sibling repo while each anchor stays inside the side that owns the line.

The Spec axis measures against two sources: the originating spec and the change's own claim about itself — the PR description when there is one, the delta's commit messages when there is not. **Divergence between the two is a finding.**

When the diff touches a file an agent reads, `writing-for-agents` judges that file.

**Done when** every finding carries an anchor.

### 3. Check every finding

A sub-agent's finding is a hypothesis until a command reproduces it. Five checks eliminate most of them:

- **The repo beats the bar**: what the spec asks for by number is not excess, and a documented standard beats a generic smell.
- **The anchor lands in a hunk**: take every line number from `pr.diff-line`, because a comment on the wrong line discredits the rest and a line outside every hunk is refused outright.
- **The head is the one you reviewed**: compare it against step 1's SHA, and say so in the general comment when it advanced.
- **The finding is new**: read the live findings from the prior review of this branch, because one that repeats an existing finding belongs in that section as a reply.
- **The old finding is spent**: one from an earlier run whose subject the current head fixes gets resolved instead of repeated, which is what makes a second review of the same branch safe.

**Done when** every finding has been reproduced, dropped, or folded into the one that already carries it, and every spent finding reads as resolved.

### 4. Write the review (`writing-guidelines`, `writing-for-agents`)

One general comment, and one anchored finding per line that clears the bar:

- **General**: open with what the change delivers, name what blocks the merge, and close with the count per axis. Link the sibling when there is a pair.
- **Anchored**: state what is wrong, cite the evidence from the file or the spec, and show the output. One subject per finding.
- **Suggestion**: when the fix is a known set of lines, carry it as a suggestion block, so the author applies it instead of retyping it.

Give every finding the four fields `pr-fix` sorts on: **file**, **line**, the **change** it asks for, and its **axis**. Mark the ones that gate the merge `blocker: yes`.

**Done when** every sentence asserts a fact checked in step 3.

### 5. Land the review (`pr`)

Detached, write the review file to `.claude/reviews/<branch>-<head-short>.md` and tell the user the path: that file is the deliverable, and `pr-fix` takes it as its subject.

Attached, post each finding on its anchor through `thread.create`, a repeat as a reply on the section that already carries it, and raise every blocker the way the adapter serves blockers. The review file is still written, as the local record of what was posted.

**Done when** the review exists at a named path, its anchors are the ones step 3 intended, and every merge blocker appears exactly once.

### 6. Report the findings

Report `## Standards` and `## Spec` as separate sections, each ranked within itself, and give the count and the worst finding per axis: one winner picked across both axes collapses the separation. Close on the verdict you would give — approve, request changes, or decline — and, attached, leave the command to the user.

**Done when** every finding from step 3 appears in exactly one section, and the review file's path is named.
