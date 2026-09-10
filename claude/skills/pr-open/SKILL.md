---
name: pr-open
description: "Turn the current branch into a pull request: read the change, make the case for it, settle the target and reviewers, then open it on the forge."
argument-hint: "<target-branch> or nothing"
disable-model-invocation: true
---

# Open a pull request

Turn the work on the current branch into a pull request on the forge. `pr-review` is what runs next on what this skill opens.

Call the Skill tool with `pr` first, for the forge vocabulary and the operation contract every step below calls by name. Opening a change needs the adapter alone, not its feedback half. **The case** is this skill's own word: the description that makes the argument for the change.

## The case

The **case** is the description: what the diff cannot show. The reviewer reads the code from the diff. The description spends its lines on the problem the change answers, the decisions it makes and the alternatives it turned down, and the evidence that it works. A description that narrates the diff file by file makes no case.

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

Drop a section with nothing to say in it. A **pair** gets the sibling's link in both descriptions, because a reviewer who reads one side alone judges half the change.

## Process

### 1. Read the change

Settle the target the way `pr` reads identity, then read what the branch adds before writing a word about it:

```bash
git status --short                     # a dirty tree is uncommitted work, not PR work
git log --oneline <target>..HEAD
git diff <target>...HEAD --stat
```

Carry a disagreement between the argument and the base to step 3. Check whether the branch already has an open PR: one means step 5 updates rather than creates, which is the first thing that step decides.

A dirty tree stops the step, per `pr`: report the files and let the user say what belongs to this change.

**Done when**:

- the forge is named and the target resolves
- every commit and changed file on the branch is accounted for
- the tree is clean
- any existing PR for this branch is named with its ID

### 2. Check the change is ready to read

A reviewer's first pass finds what the author could have found alone, so find it first. Run the repo's own checks, the way `pr` describes them.

Read the diff for what belongs to a different change: a stray file, a debug line, a rename that rides along. Commit each one away, or name it in the description's Notes.

**Done when** the repo's checks pass locally and every changed file traces to the change the PR is for.

### 3. Grill the gaps

Carry the whole frontier into one round, the way `pr` describes it. The diff shows the decisions and hides the reasons, and the reasons are what the case is made of. The frontier holds:

- the reason behind each decision a reviewer would question
- the target, when step 1 left it ambiguous
- the reviewers beyond the ones `pr.reviewers` says the repo adds on its own
- whether the PR opens as a draft

**Done when** every question holds an answer, and the target, the reviewers, and draft-or-ready are settled.

### 4. Write the case

Write the title and the description the way `pr` describes writing, to a file, so step 5 passes the body as a file and skips shell quoting. The title is one line naming the change in the repo's own vocabulary, matching how the branch's own history titles things.

**Done when** the title and description are on disk at a named path, every section of the case is either filled or dropped, and every sentence asserts a fact from step 1, 2, or 3.

### 5. Open the PR

Push the branch first, because a PR against an unpushed head has nothing to show:

```bash
git fetch origin <source-branch>   # a branch already on the remote may hold work you do not
git push -u origin HEAD
```

A remote branch that holds commits this one does not is branch drift, and `pr` says what to do about it. A rejected push is the same drift arriving late: re-read the remote and rebase, never `--force`.

Take the branch step 1 found:

- **An existing PR**: `pr.update` with the title, the description file, the target, and the reviewers, then go to the read-back. `pr.create` against a PR that exists errors, and by then the push has already landed.
- **No PR**: `pr.create` with the target, the description file, the reviewers, and the draft flag from step 3.

Read it back through `pr.identity` and confirm the target, the reviewers, and the state are the ones step 3 settled. A pair opens both, then updates each description to carry the other's link, since neither link exists until both exist.

Then read `checks.read` on the head, and `checks.log` for anything red. A check red for the change is step 2's work again: fix it and push. `pr` says what closes the step short of green.

**Done when** the PR exists with its ID, target, reviewers, and state reported; both sides of a pair link each other; and the head is green or carries the note explaining why it is not.
