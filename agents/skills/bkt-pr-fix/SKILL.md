---
name: bkt-pr-fix
description: "Work the review comments on a PR: fix what is settled, grill what is open, then reply and resolve."
disable-model-invocation: true
---

Read the review comments on a PR, settle what they ask for, and land the fixes. This skill orchestrates others, so each step names the skill that governs it, and that skill rules its own part.

## The fork

Every live thread is one of two, and the label decides which step handles it:

- **Settled**: the comment determines one defensible change. Step 4 applies it.
- **Open**: the comment admits more than one defensible change, or it disputes a decision the code already makes. Step 3 grills it.

Label a borderline thread **open**: the interview costs a round, while a silent pick spends a decision that belongs to the user.

## Process

### 1. Read the comments (`bkt`)

```bash
bkt pr comments <id> --repo <slug> --details
bkt pr view <id> --repo <slug> --json
```

`--details` carries the file, the line, the resolved flag, and the task status. On Cloud, `--state unresolved` narrows the list. Data Center leaves resolution status out of the API, so read the replies on each thread to tell a live one from a handled one.

Thread IDs and reply IDs differ: every later command takes the top-level comment ID of the thread.

**Done when** every live thread is listed with its thread ID, its anchor (file and line in the new file), and the change it asks for.

### 2. Sort every thread

Read the anchored code before labelling, because the comment is a claim about the diff and the diff is the evidence. A comment that misreads the code is still a thread to answer, labelled settled with no change attached.

**Done when** every thread carries one label from the fork, and every settled thread names the change it takes.

### 3. Grill the open threads (`grill-with-docs`)

Call the Skill tool for `grill-with-docs`, carrying every open thread into a single interview: it asks a whole frontier per round, so one pass settles the batch. Give each question the reviewer's words, the anchored code, and your recommended answer.

**Done when** every open thread holds an answer from the user, and the ADRs and glossary entries the interview produced are on disk.

### 4. Apply the fixes (`karpathy-guidelines`)

Change what the thread asks for and stop there; `karpathy-guidelines` governs the edit. Keep one commit per thread, so step 5 can cite a SHA per reply.

A thread also lands without a code change when the reviewer read the diff wrong or the repo already covers the point. Write down that reason, because it becomes the reply.

**Done when** every thread has a commit that addresses it or a written reason it takes none, and the repo's checks pass.

### 5. Reply and resolve (`bkt`, `writing-guidelines`)

Push first, so every reply cites a SHA that exists on the remote.

```bash
bkt pr comment <id> --repo <slug> --parent <thread-id> --text "$(cat <file.md>)"
bkt pr comments resolve <id> <thread-id> --repo <slug>
bkt pr task complete <id> <task-id> --repo <slug>
```

One reply per thread, naming what changed and the commit that changed it, or the reason the thread takes no change. `writing-guidelines` governs the voice: active, concise, filler cut.

Resolve the threads you fixed. Leave open, with the reply as its answer, any thread the interview turned back into a question for the reviewer.

**Done when** `bkt pr comments <id> --json` shows a reply on every thread from step 1.
