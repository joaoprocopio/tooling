---
name: bkt-pr-fix
description: "Work the review comments on a PR: fix what is settled, grill what is open, discuss the rest, then reply and resolve."
disable-model-invocation: true
---

Read the review comments on a PR, settle what they ask for, land the fixes, and close every thread. Call the Skill tool for `bkt-pr` first, which carries the anchors, threads, suggestions, resolution, and tasks every step below uses. `bkt-pr-review` is the other half of the loop: it writes the threads this skill works.

## The subject

The skill's argument names the feedback to work, and it decides which steps run:

- **One PR, or several**: PRs passed together are a single change, so read every thread across all of them before fixing any one of them, and a fix in one repo can settle a thread in its sibling.
- **A `bkt-pr-review` report**, when the review ran against a bare ref and posted nothing: each finding is a thread with no ID, so steps 2 through 4 run and step 5 answers the user instead of the PR.
- **Nothing**: ask which of the two before reading.

## The fork

Every live thread is one of two, and the label decides which step handles it:

- **Settled**: the comment determines one defensible change. Step 4 applies it.
- **Open**: the comment admits more than one defensible change, or it disputes a decision the code already makes. Step 3 grills it.

Label a borderline thread **open**: the interview costs a round, while a silent pick spends a decision that belongs to the user.

A thread ends in one of three states, and step 5 puts it there: **fixed** (a commit addresses it), **answered** (a reply gives the reason it takes no change), or **discussed** (a reply contests the claim or asks the reviewer a question, and the thread stays open for them).

## Process

### 1. Read the comments (`bkt-pr`)

The general comment carries no anchor and usually names what blocks the merge, so read it as a thread like any other and give it the whole diff as its subject.

**Done when** every live thread, general and inline, is listed with its thread ID, its anchor, the change it asks for, and any suggestion or task ID hanging off it.

### 2. Sort every thread

Read the anchored code before labelling, because the comment is a claim about the diff and the diff is the evidence. A comment that misreads the code is still a thread to answer: label it settled, with no change attached and the misreading written down.

The head moves after a review lands, and a comment's line number ages with it. Confirm the anchor still points at the code the comment describes; when the line drifted, re-anchor the thread and carry the new number into every later step. A thread whose subject the head already removed is settled and answered.

**Done when** every thread carries one label from the fork, a current anchor, and, when settled, the change it takes.

### 3. Grill the open threads (`grill-with-docs`)

Call the Skill tool for `grill-with-docs`, carrying every open thread into a single interview: it asks a whole frontier per round, so one pass settles the batch. Give each question the reviewer's words, the anchored code, and your recommended answer.

An answer can also be that the reviewer is wrong, which routes the thread to **discussed** rather than to a commit.

**Done when** every open thread holds an answer from the user, and the ADRs and glossary entries the interview produced are on disk.

### 4. Apply the fixes (`karpathy-guidelines`)

Change what the thread asks for and stop there; `karpathy-guidelines` governs the edit. Apply an attached suggestion rather than retyping it, previewing it first because the reviewer's line numbers age with every push. Keep one commit per thread, so step 5 can cite a SHA per reply.

**Done when** every settled thread has a commit that addresses it or a written reason it takes none, and the repo's checks pass.

### 5. Reply and close out (`bkt-pr`, `writing-guidelines`)

Push first, so every reply cites a SHA that exists on the remote. Then reply once per thread and put it in its end state:

- **Fixed**: name what changed and the commit that changed it, then resolve the thread and complete its task.
- **Answered**: give the reason the thread takes no change, cite the file or spec that carries the evidence, then resolve.
- **Discussed**: ask the question or contest the claim with the evidence, and leave the thread open for the reviewer.

`writing-guidelines` governs the voice: active, concise, filler cut. Reopen a thread the reviewer revives, and work it from step 2.

A red build on the pushed head is worth a reply of its own on the general thread.

**Done when** every thread from step 1 carries a reply, every fixed or answered thread reads as resolved, and the pushed head builds green.
