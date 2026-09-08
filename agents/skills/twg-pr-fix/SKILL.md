---
name: twg-pr-fix
description: "Work the review comments on a PR: fix what is settled, grill what is open, discuss the rest, then reply and resolve."
argument-hint: "<pr-id…> or a twg-pr-review report"
disable-model-invocation: true
---

Read the review comments on a PR, settle what they ask for, land the fixes, and close every thread. Call the Skill tool for `twg-pr` first, which carries checkout, anchors, drift, threads, suggestions, resolution, tasks, and the voice every step below uses. `twg-pr-review` is the other half of the loop: it writes the threads this skill works.

## The subject

The skill's argument names the feedback to work, and it decides which steps run:

- **One PR, or a pair**: every thread across the pair is in scope, and a fix in one repo can settle a thread in its sibling.
- **A `twg-pr-review` report**, when the review ran against a bare ref and posted nothing: each finding arrives with a file, a line, a change, and an axis, and carries no thread ID. Steps 2 through 4 run on the findings, and step 5 answers the user instead of the PR.
- **Nothing**: ask which of the two before reading.

## The fork

Every live thread is one of two, and the label decides which step handles it:

- **Settled**: the comment determines one defensible change. Step 4 applies it.
- **Open**: the comment admits more than one defensible change, or it disputes a decision the code already makes. Step 3 grills it.

Label a borderline thread **open**: the interview costs a round, while a silent pick spends a decision that belongs to the user.

A thread ends in one of four states, and step 5 puts it there:

- **Fixed**: a commit addresses it.
- **Answered**: a reply gives the reason it takes no change.
- **Deferred**: the reviewer is right and the work sits outside this PR, so a reply names the issue that now carries it.
- **Discussed**: a reply contests the claim or asks the reviewer a question, and the thread stays open for them.

## Process

### 1. Read the comments and check out (`twg-pr`)

Check the PR out first, so steps 4 and 5 have the branch they edit and push.

Read every live thread, general and inline. The general comment carries no anchor and is where the reviewer names what blocks the merge, so read it as a thread like any other and give it the whole diff as its subject. Run `twg bb prs task query` alongside the comments, because a blocker's task ID differs from its thread ID and step 5 resolves the task by that ID.

**Done when** every live thread is listed with its thread ID, its anchor, the change it asks for, and any suggestion or task ID attached to it. Working from a report instead, every finding is listed with its file, line, and change.

### 2. Sort every thread

Read the anchored code before labelling, because the comment is a claim about the diff and the diff is the evidence. A comment that misreads the code is still a thread to answer: label it settled, with no change attached and the misreading written down.

Resolve drift here: a review lands against a head that has since moved, so confirm each anchor before carrying its number into any later step.

**Done when** every thread carries one label from the fork, a current anchor, and, when settled, the change it takes.

### 3. Grill the open threads (`grilling`)

Call the Skill tool for `grilling`, carrying every open thread into a single interview: it asks a whole frontier per round, so one pass settles the batch. Give each question the reviewer's words, the anchored code, and your recommended answer.

An answer can also be that the reviewer is wrong, which routes the thread to **discussed** rather than to a commit. When the interview settles a term or a decision the repo records, call the Skill tool for `domain-modeling` and write the glossary entry or ADR it earns; a thread that changes only the lines under it needs neither.

When no user is there to answer, put every open thread in **discussed** and ask the reviewer in the thread, which keeps the decision with a human.

**Done when** every open thread holds an answer, from the user or from the reviewer's own thread.

### 4. Apply the fixes (`karpathy-guidelines`)

Change what the thread asks for and stop there; `karpathy-guidelines` governs the edit. Apply an attached suggestion by putting its fenced block in place of the anchored lines, confirming first that those lines still hold what the suggestion replaces. Keep one commit per thread, so step 5 can cite a SHA per reply.

Run the repo's own checks, reading the command from the environment: the test and lint scripts in the package manifest, the task runner, or the CI config.

**Done when** every settled thread has a commit that addresses it or a written reason it takes none, and the repo's checks pass locally.

### 5. Reply and close out (`twg-pr`, `writing-guidelines`)

Push first, so every reply cites a SHA that exists on the remote. Then reply once per thread and put it in its end state:

- **Fixed**: name what changed and the commit that changed it, then resolve the thread and its task.
- **Answered**: give the reason the thread takes no change, cite the file or spec that carries the evidence, then resolve.
- **Deferred**: name the issue now tracking the work and the reason it sits outside this PR, then resolve the thread and its task.
- **Discussed**: ask the question or contest the claim with the evidence, and leave the thread open for the reviewer.

Read the statuses on the pushed head. A build red for the change is step 4's work again, so reopen the thread it belongs to and go back. A build red for a cause outside the diff takes a reply of its own on the general thread naming that cause, which is what closes this step short of green.

Reopen a thread the reviewer revives, and work it from step 2.

**Done when** every thread from step 1 carries a reply, every fixed, answered, or deferred thread reads as resolved, and the pushed head builds green or carries the reply explaining why it does not.
