---
name: twg-pr-review
description: "Review a PR, or a delta against a fixed point, along two axes, and return findings anchored to the line."
argument-hint: "<pr-id…> or <ref>"
disable-model-invocation: true
---

Review a Bitbucket PR, or a delta against any ref, along two axes: Standards and Spec. Call the Skill tool for `twg-pr` first, which carries checkout, anchors, drift, threads, suggestions, resolution, tasks, and the voice every step below uses. `twg-pr-fix` is the other half of the loop: it works the threads this skill writes.

## The fixed point

The skill's argument is what the diff is measured against, and it decides every step below:

- **One PR, or a pair**: the fixed point is each PR's declared target, read in step 1.
- **A ref**, `HEAD~1`, a tag, a SHA, or a branch: the fixed point is the ref, the review covers the delta, and step 6 reports the findings instead of posting them.
- **Nothing**: ask which of the two before measuring.

Confirm the ref resolves and the diff is non-empty before dispatching the axes, because a bad ref is cheaper to catch here than inside two sub-agents.

## The bar

Post a finding that changes the code or changes the merge decision. A finding that changes neither belongs in the report alone, where it costs the author a read instead of a thread. `karpathy-guidelines` sets what counts as a finding at all.

## Process

### 1. Read and check out the PRs (`twg-pr`)

Check each PR out, so the diff the axes measure is the head the server holds and the head SHA is a fact from git rather than an assumption.

**Done when** every PR has its target, its head SHA, its description, and a local branch.

### 2. Measure both axes (`code-review`)

Dispatch both axes in parallel, in a single message. Run the two axes once per PR, giving each run the other PRs in the pair as context, so a finding can name the sibling repo while each anchor stays inside the PR that owns the line.

The Spec axis measures against two sources: the originating spec and the PR description. **Divergence between the two is a finding.** When the fixed point is a bare ref, the spec is whatever the delta's commit messages promise.

When the diff touches a file an agent reads, `writing-for-agents` judges that file.

**Done when** every finding carries an anchor.

### 3. Check every finding

A sub-agent's finding is a hypothesis until a command reproduces it. Five checks eliminate most of them:

- **The repo beats the bar**: what the spec asks for by number is not excess, and a documented standard beats a generic smell.
- **The anchor lands in a hunk**: take every line number from `twg bb prs diff-line`, because a comment on the wrong line discredits the rest and a line outside every hunk is refused outright.
- **The head is the one you reviewed**: compare it against step 1's SHA, and say so in the general comment when it advanced.
- **The thread exists**: read the live threads, because a finding that repeats one belongs in that thread as a reply.
- **The old thread is spent**: a thread from an earlier run of this skill whose finding the current head fixes gets resolved instead of repeated, which is what makes a second review of the same PR safe.

**Done when** every finding has been reproduced, dropped, or folded into the thread that already carries it, and every spent thread is resolved.

### 4. Write the comments (`writing-guidelines`, `writing-for-agents`)

One general comment per PR, and one inline comment per anchor that clears the bar:

- **General**: open with what the change delivers, name what blocks the merge, and close with the count per axis. Link the sibling PR when there is a pair.
- **Inline**: state what is wrong, cite the evidence from the file or the spec, and show the output. One subject per comment.
- **Suggestion**: when the fix is a known set of lines, carry it as a suggestion block, so the author applies it instead of retyping it.

`writing-for-agents` governs the cut, because agents read PR comments too: keep the sentences that change a decision, and phrase the ask positively, saying what to do.

**Done when** every sentence asserts a fact checked in step 3.

### 5. Post the comments (`twg-pr`)

Run this step when the fixed point came from a PR. Post each finding on its anchor and a repeat as a reply on the thread that already carries it.

Raise every merge blocker as a task attached to its thread: the thread carries the finding and the evidence, and the task's one line names the change that unblocks the merge. `twg-pr-fix` closes the blocker against that task.

**Done when** the posted threads carry the anchors you intended, and every merge blocker exists once, as a task attached to its thread.

### 6. Report the findings

Report `## Standards` and `## Spec` as separate sections, each ranked within itself, and give the count and the worst finding per axis: one winner picked across both axes collapses the separation. Close on the verdict you would give the PR, approve, request changes, or decline, and leave the command to the user.

When the fixed point is a bare ref, this report is the deliverable and `twg-pr-fix` takes it as its subject, so give every finding the four fields that skill sorts on: **file**, **line**, the **change** it asks for, and its **axis**. Nothing carries a thread ID, because nothing was posted.

**Done when** every finding from step 3 appears in exactly one section, and each one posted also names its thread ID.
