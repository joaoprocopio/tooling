---
name: pr-fix
description: "Work the review feedback on a change: fix what is settled, grill what is open, discuss the rest, then reply and close every finding."
argument-hint: "<review file>, a PR id, or nothing"
disable-model-invocation: true
---

Read the review feedback on a change, settle what it asks for, land the fixes, and close every finding. Call the Skill tool for `pr` first, which carries checkout, anchors, drift, the review file, suggestions, blockers, and the voice every step below uses. `pr-review` is the other half of the loop: it writes the findings this skill works.

## The subject

The skill's argument names the feedback to work, and it decides which steps run:

- **A review file** from `pr-review`: each finding arrives with a file, a line, a change, and an axis. Step 5 writes its outcome back into that file.
- **A PR id, or a pair**: every live thread across the pair is in scope, and a fix in one repo can settle a finding in its sibling. This needs an adapter; with none loaded, ask for the review file instead.
- **Nothing**: ask which before reading.

## The fork

Every live finding is one of two, and the label decides which step handles it:

- **Settled**: it determines one defensible change. Step 4 applies it.
- **Open**: it admits more than one defensible change, or it disputes a decision the code already makes. Step 3 grills it.

Label a borderline finding **open**: the interview costs a round, while a silent pick spends a decision that belongs to the user.

A finding ends in one of four states, and step 5 puts it there:

- **Fixed**: a commit addresses it.
- **Answered**: a reply gives the reason it takes no change.
- **Deferred**: the reviewer is right and the work sits outside this change, so a reply names the issue that now carries it.
- **Discussed**: a reply contests the claim or asks the reviewer a question, and the finding stays open for them.

## Process

### 1. Read the feedback and check out (`pr`)

Resolve detached or attached, and say which. Check the branch out first, so steps 4 and 5 have the branch they edit.

Read every live finding, general and anchored. The general comment carries no anchor and is where the reviewer names what blocks the merge, so read it like any other finding and give it the whole diff as its subject. Read the blockers alongside, because step 5 closes each one against the merge decision.

**Done when** every live finding is listed with its ID, its anchor, the change it asks for, and any suggestion or blocker attached to it.

### 2. Sort every finding

Read the anchored code before labelling, because the finding is a claim about the diff and the diff is the evidence. A finding that misreads the code is still one to answer: label it settled, with no change attached and the misreading written down.

Resolve drift here: a review lands against a head that has since moved, so confirm each anchor against the current head before carrying its number into any later step.

**Done when** every finding carries one label from the fork, a current anchor, and, when settled, the change it takes.

### 3. Grill the open findings (`grilling`)

Carry every open finding into a single interview, the way `pr` describes the frontier. Give each question the reviewer's words, the anchored code, and your recommended answer.

An answer can also be that the reviewer is wrong, which routes the finding to **discussed** rather than to a commit. When the interview settles a term or a decision the repo records, call the Skill tool for `domain-modeling` and write the glossary entry or ADR it earns; a finding that changes only the lines under it needs neither.

When no user is there to answer, put every open finding in **discussed** and write the question into it, which keeps the decision with a human.

**Done when** every open finding holds an answer, from the user or from the question left for the reviewer.

### 4. Apply the fixes (`karpathy-guidelines`)

Change what the finding asks for and stop there; `karpathy-guidelines` governs the edit. Apply an attached suggestion by putting its fenced block in place of the anchored lines, confirming first that those lines still hold what the suggestion replaces. Keep one commit per finding, so step 5 can cite a SHA apiece.

Run the repo's own checks, the way `pr` describes local checks.

**Done when** every settled finding has a commit that addresses it or a written reason it takes none, and the repo's checks pass locally.

### 5. Reply and close out (`pr`, `writing-guidelines`)

Push first, so every reply cites a SHA that exists on the remote. Then reply once per finding and put it in its end state:

- **Fixed**: name what changed and the commit that changed it, then close it and its blocker.
- **Answered**: give the reason it takes no change, cite the file or spec that carries the evidence, then close it.
- **Deferred**: name the issue now tracking the work and the reason it sits outside this change, then close it and its blocker.
- **Discussed**: ask the question or contest the claim with the evidence, and leave it open for the reviewer.

Detached, that means updating each section's `state` line in the review file and appending the reply under it. Attached, the same text goes to `thread.reply` and `thread.resolve`.

Read the checks on the pushed head. A check red for the change is step 4's work again, so reopen the finding it belongs to and go back. A check red for a cause outside the diff takes a reply of its own on the general comment naming that cause, which is what closes this step short of green.

Reopen any finding the reviewer revives, and work it from step 2.

**Done when** every finding from step 1 carries a reply, every fixed, answered, or deferred one reads as closed, and the pushed head is green or carries the reply explaining why it is not.
