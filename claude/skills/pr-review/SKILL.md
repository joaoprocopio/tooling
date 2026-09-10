---
name: pr-review
description: "Review a change against a fixed point along two axes, and post findings anchored to the line."
argument-hint: "<ref>, a PR id, or nothing"
disable-model-invocation: true
---

# Review a change

Review a change along two axes, **Standards** and **Spec**, and land the findings on the forge. `pr-fix` is the other half of the loop: it works the findings this skill posts.

This skill is built on a shared vocabulary and a shared brief:

- Call the Skill tool with `pr` for the forge vocabulary (**forge**, **adapter**, **fixed point**, **pair**, **budget**, **anchor**, **drift**, **thread**, **suggestion**, **blocker**, **check**, **verdict**) and the operation contract every step below calls by name. Resolve the adapter first and say which forge you got.
- [`axes.md`](axes.md) carries the two briefs, the spec and standards sources, the smell baseline, and the eight fields a finding comes back with. Step 2 dispatches from it.

The other skills are step-local: each step names the ones it calls, and calls them before doing its own work.

## The fixed point

The skill's argument is what the diff measures against, and it decides every step below:

- **A PR id, or a pair**: the fixed point is each PR's declared target, read from `pr.identity`
- **A ref**: `HEAD~1`, a tag, a SHA, or a branch, and the review covers that delta
- **Nothing**: read `pr.queue` for what is waiting on the user, offer it, and ask which before measuring

Confirm the ref resolves and the diff is non-empty before dispatching the axes, because a bad ref is cheaper to catch here than inside two sub-agents.

## The bar

Post a finding that changes the code or changes the merge decision. A finding that changes neither belongs in the chat report alone, where it costs the author a read instead of a thread. Call the Skill tool with `karpathy-guidelines` for what counts as a finding at all.

## Process

### 1. Resolve the subject

Read `pr.identity` for every side of the subject, then fetch and check out, so the diff the axes measure is the head you report on and the head SHA is a fact rather than an assumption. Read `pr.files` before the diff itself, since its shape sets step 2's budget.

**Done when** the forge is named, the fixed point, the source branch, the head SHA, the description, and the changed files are known for every side of the subject, and a local branch holds each one.

### 2. Measure both axes

Resolve the spec and standards sources the way `axes.md` orders them, then dispatch the two axes in parallel in a single message, each with its brief and the smell baseline pasted in.

Run the two axes once per side of a pair, giving each run the other sides as context, so a finding can name the sibling repo while each anchor stays inside the side that owns the line.

Dispatch per group of files when `pr.files` says the diff is large, the way `pr` budgets one.

When the diff touches a file an agent reads, call the Skill tool with `writing-for-agents` and judge that file by it.

**Done when** every finding carries the fields `axes.md` names, including the line text step 3 anchors it by.

### 3. Check every finding

A sub-agent's finding is a hypothesis until a command reproduces it. Five checks eliminate most of them:

- **The repo beats the bar**: what the spec asks for by number is not excess, and a documented standard beats a generic smell
- **The anchor lands in a hunk**: take every line number from `pr.diff-line`, because a comment on the wrong line discredits the rest and a line outside every hunk is refused outright
- **The head is the one you reviewed**: compare it against step 1's SHA, and say so in the general comment when it advanced
- **The finding is new**: read the live threads through `thread.list`, because a finding that repeats an open one belongs in that thread as a reply
- **The old finding is spent**: one from an earlier run whose subject the current head fixes gets resolved instead of repeated, which is what makes a second review of the same branch safe

**Done when** every finding has been reproduced, dropped, or folded into the thread that already carries it, and every spent finding reads as resolved.

### 4. Write the review

Call the Skill tool with `writing-guidelines`, and with `writing-for-agents` when the diff touches a file an agent reads. Then write one general comment, plus one anchored finding per line that clears the bar:

- **General**: open with what the change delivers, name what blocks the merge, and close with the count per axis. Link the sibling when there is a pair.
- **Anchored**: state what is wrong, cite the evidence from the file or the spec, and show the output. One subject per finding.
- **Suggestion**: when the fix is a known set of lines, carry it as a suggestion block, so the author applies it instead of retyping it.

Carry the fields `axes.md` returned into what you post: the **file** and the **line** step 3 anchored, the **change** it asks for, and its **axis**, which is what `pr-fix` sorts on. Mark the ones that gate the merge as blockers.

**Done when** every sentence asserts a fact checked in step 3.

### 5. Post the review

Post each finding on its anchor through `thread.create`, post a repeat as a reply on the thread that already carries it, and raise each blocking finding through `blocker.create` against the thread that carries its evidence.

Read back through `thread.list` and confirm each anchor is the one step 3 intended. A rejected post is the forge refusing the anchor: re-run `pr.diff-line` and post again.

**Done when** every finding appears on the forge exactly once, on the anchor step 3 intended, and every merge blocker is raised exactly once.

### 6. Report the findings

Report `## Standards` and `## Spec` as separate sections in chat, each ranked within itself, and give the count and the worst finding per axis. One winner picked across both axes collapses the separation.

Close on the verdict you would give, approve, request changes, or decline, and leave the command to the user.

**Done when** every finding from step 3 appears in exactly one section, and the PR carrying the threads is named with its ID.
