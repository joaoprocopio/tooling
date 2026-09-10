---
name: pr-open
description: "Turn the current branch into a pull request: read the change, make the case for it, settle the target and reviewers, and open it or hand over the command that does."
argument-hint: "<target-branch> or nothing"
disable-model-invocation: true
---

Turn the work on the current branch into a pull request. Call the Skill tool for `pr` first, which carries identity, the target, the pair, checks, and the voice every step below uses. `pr-review` is what runs next on what this skill opens.

Detached, this skill takes the change all the way to the point of creation and hands over the last move: the branch is pushed, the case is on disk, and the user gets the command or the URL that opens the PR. Attached, step 5 runs it.

## The target

The **target** is the branch the change merges into, and it is a decision, not a default: every forge falls back to the repository's main branch, which is wrong whenever the change **stacks**, sitting on top of another branch still in review. Settle it explicitly, taking it from the skill's argument, else from the branch the work was cut from:

```bash
git log --oneline --decorate main..HEAD    # the commits this branch adds
git merge-base --fork-point main HEAD      # where it left the trunk
```

Step 3 puts the target to the user when the two disagree.

## The case

The **case** is the description: what the diff cannot show. The reviewer reads the code from the diff, so the description spends its lines on the problem the change answers, the decisions it makes and the alternatives it turned down, and the evidence that it works. A description that narrates the diff file by file makes no case and costs the reviewer a read.

```markdown
## What

One paragraph: the problem, and what the change does about it.

## Why this shape

The decisions a reviewer would otherwise raise, each with the reason it went that way.

## Evidence

The commands run and their result: tests, migration, manual check.

## Notes

What is out of scope, what a follow-up carries, and the sibling PR when there is a pair.
```

Drop a section with nothing to say in it. A **pair**, one change split across repos, gets the sibling's link in both descriptions, because a reviewer who reads one side alone judges half the change.

## Process

### 1. Read the change (`pr`)

Resolve detached or attached, and say which. Then read what the branch actually adds before writing a word about it:

```bash
git status --short                     # a dirty tree is uncommitted work, not PR work
git log --oneline <target>..HEAD
git diff <target>...HEAD --stat
```

Attached, check whether the branch already has an open PR: one means the change is up already, and step 5 updates it instead of creating a second.

**Done when** the target resolves, every commit and changed file on the branch is accounted for, the tree is clean, and any existing PR for this branch is named with its ID.

### 2. Check the change is ready to read

A reviewer's first pass finds what the author could have found alone, so find it first. Run the repo's own checks, the way `pr` describes local checks.

Read the diff for what belongs to a different change: a stray file, a debug line, a rename that rides along. Each is either committed away or named in the description's Notes.

**Done when** the repo's checks pass locally and every changed file traces to the change the PR is for.

### 3. Grill the gaps (`grilling`)

The diff shows the decisions and hides the reasons, and the reasons are what the case is made of. Carry the whole frontier into one round, the way `pr` describes it: the reason behind each decision a reviewer would question, the target when step 1 left it ambiguous, the reviewers beyond whatever the repo adds on its own, and whether the PR opens as a draft.

When no user is there to answer, open as a draft and write each unanswered question into the Notes section, which keeps the decision with a human.

**Done when** every question holds an answer, and the target, the reviewers, and draft-or-ready are settled.

### 4. Write the case (`writing-guidelines`, `writing-for-agents`)

Write the title and the description to a file, so step 5 passes the body as a file rather than fighting shell quoting.

The title is one line naming the change in the repo's own vocabulary, matching how the branch's own history titles things. `writing-for-agents` governs the cut, because agents read PR descriptions too: keep the sentences that change a decision, and phrase each one positively, saying what the change does.

**Done when** the title and description are on disk at a named path, every section of the case is either filled or dropped, and every sentence asserts a fact from step 1, 2, or 3.

### 5. Open the PR (`pr`)

Push the branch first, because a PR against an unpushed head has nothing to show:

```bash
git push -u origin HEAD
```

Detached, that push prints the forge's own create-PR URL. Hand the user that URL, the path to the description file, and the settled target, reviewers, and draft-or-ready from step 3 — everything the last move needs, so it is one paste rather than a retype.

Attached, create the PR through the adapter with the target, the description file, the reviewers, and the draft flag, then read it back and confirm the target, the reviewers, and the state are the ones step 3 settled. Update an existing PR in place rather than opening a second. A pair opens both, then updates each description to carry the other's link, since neither link exists until both exist.

Then read the checks on the head. A check red for the change is step 2's work again, so fix it and push; one red for a cause outside the diff is named as such in the PR, which is what closes this step short of green.

**Done when** the PR exists, or the user holds everything needed to create it in one move; the target, the reviewers, and the state are reported; both sides of a pair link each other; and the head is green or carries the note explaining why it is not.
