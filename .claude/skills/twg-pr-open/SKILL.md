---
name: twg-pr-open
description: "Open a PR on Bitbucket: read the change, make the case for it in the description, settle the target and reviewers, and create it."
argument-hint: "<target-branch> or nothing"
disable-model-invocation: true
---

Turn the work on the current branch into a pull request. Call the Skill tool for `twg-pr` first, which carries identity, the pair, comments, checks, and the voice every step below uses. `twg-pr-review` is what runs next on what this skill opens.

## The target

The **target** is the branch the change merges into, and it is a decision, not a default: `twg bb prs create` falls back to the repository's main branch, which is wrong whenever the change **stacks**, sitting on top of another branch still in review. Pass `--dest` on every create, taking it from the skill's argument, else from the branch the work was cut from:

```bash
git log --oneline --decorate main..HEAD    # the commits this branch adds
git merge-base --fork-point main HEAD      # where it left the trunk
```

Step 3 puts the target to the user when the two disagree.

## The case

The **case** is the description: what the diff cannot show. The reviewer reads the code from `twg bb prs diff`, so the description spends its lines on the problem the change answers, the decisions it makes and the alternatives it turned down, and the evidence that it works. A description that narrates the diff file by file makes no case and costs the reviewer a read.

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

Drop a section with nothing to say in it. A **pair**, one change split across repos, gets the sibling's link in both descriptions, because a reviewer who reads one PR alone judges half the change.

## Process

### 1. Read the change

Read what the branch actually adds before writing a word about it:

```bash
git status --short                     # a dirty tree is uncommitted work, not PR work
git log --oneline <target>..HEAD
git diff <target>...HEAD --stat
```

Then check whether the branch already has a PR:

```bash
twg bb prs query --source "$(git branch --show-current)" --state OPEN -o json
```

An open PR from this branch means the change is already up: step 5 updates it instead of creating a second one.

**Done when** the target resolves, every commit and changed file on the branch is accounted for, the tree is clean, and any existing PR for this branch is named with its ID.

### 2. Check the change is ready to read

A reviewer's first pass finds what the author could have found alone, so find it first. Run the repo's own checks, reading the command from the environment: the test and lint scripts in the package manifest, the task runner, or the CI config.

Read the diff for what belongs to a different change: a stray file, a debug line, a rename that rides along. Each is either committed away or named in the description's Notes.

**Done when** the repo's checks pass locally and every changed file traces to the change the PR is for.

### 3. Grill the gaps (`grilling`)

The diff shows the decisions and hides the reasons, and the reasons are what the case is made of. Call the Skill tool for `grilling`, carrying the whole frontier in one round: the reason behind each decision a reviewer would question, the target when step 1 left it ambiguous, the reviewers beyond the defaults, and whether the PR opens as a draft.

`twg bb prs effective-default-reviewer query` lists the reviewers the repo adds on its own, so the question is who joins them.

Give every question your recommended answer, taken from the code and the commits. When no user is there to answer, open the PR as a draft and write each unanswered question into the Notes section, which keeps the decision with a human.

**Done when** every question holds an answer, and the target, the reviewers, and draft-or-ready are settled.

### 4. Write the case (`writing-guidelines`, `writing-for-agents`)

Write the title and the description to a file, so step 5 passes the body as `--description-file <file.md>` rather than fighting shell quoting.

The title is one line naming the change in the repo's own vocabulary, matching how the existing PRs in `twg bb prs query` are titled. `writing-for-agents` governs the cut, because agents read PR descriptions too: keep the sentences that change a decision, and phrase each one positively, saying what the change does.

**Done when** the title and description are on disk, every section of the case is either filled or dropped, and every sentence asserts a fact from step 1, 2, or 3.

### 5. Create the PR (`twg-pr`)

Push the branch first, because a PR against an unpushed head has nothing to show:

```bash
git push -u origin HEAD
twg bb prs create --source "$(git branch --show-current)" --dest <branch> \
  --title "..." --description-file <file.md> --reviewer <user>... [--draft] -o json
```

For the branch that already had a PR, `twg bb prs update --pull-request <id> --title "<title>" --description-file <file.md>` updates it in place, and `--ready` on the same command is what takes a draft to ready.

Read the PR back with `twg bb prs get <id> -o json`, confirming the target, the reviewers, and the state are the ones step 3 settled; a default reviewer missing from the read-back is added with `update --add-reviewer`. A pair opens both PRs, then updates each description to carry the other's link, since neither link exists until both are created.

Then read the statuses on the head. A build red for the change is step 2's work again, so fix it and push; a build red for a cause outside the diff takes a general comment naming that cause, which is what closes this step short of green.

**Done when** the PR exists with its ID, its target, its reviewers, and its state reported to the user, both PRs of a pair link each other, and the head builds green or carries the comment explaining why it does not.
