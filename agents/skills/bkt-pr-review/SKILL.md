---
name: bkt-pr-review
description: "Review a PR, or a delta against a fixed point, along two axes, and return findings anchored to the line."
disable-model-invocation: true
---

Review a Bitbucket PR, or a delta against any ref, along two axes: Standards and Spec. This skill orchestrates others, so each step names the skill that governs it, and that skill rules its own part.

## The fixed point

The skill's argument is what the diff is measured against, and it decides every step below:

- **One PR, or several**: the fixed point is each PR's declared target, read in step 1. PRs passed together are a single change, so read them all before judging any one of them.
- **A ref**, `HEAD~1`, a tag, a SHA, or a branch: the fixed point is the ref, the review covers the delta, and step 6 reports the findings instead of posting them.
- **Nothing**: ask which of the two before measuring.

`git diff <fixed-point>...HEAD` is the diff for every read in this skill. Confirm the ref resolves and the diff is non-empty before dispatching the axes, because a bad ref is cheaper to catch here than inside two sub-agents.

## Process

### 1. Read the PRs (`bkt`)

`bkt pr view <id> --repo <slug> --json` returns the description and the declared target. Each PR carries its own target, and targets usually differ between repos in the same pair.

**Done when** every PR has its fixed point, head SHA, and description in hand.

### 2. Measure both axes (`code-review`)

Dispatch both axes in parallel, in a single message.

The Spec axis measures against two sources: the originating spec and the PR description. **Divergence between the two is a finding.** When the fixed point is a bare ref, the spec is whatever the delta's commit messages promise.

`karpathy-guidelines` sets the bar for what counts as a finding. When the diff touches a file an agent reads, `writing-for-agents` judges that file.

**Done when** every finding carries an anchor: repo, file, and line in the new file.

### 3. Check every finding

A sub-agent's finding is a hypothesis until a command reproduces it. Three checks eliminate most of them:

- **The repo beats the bar**: what the spec asks for by number is not excess, and a documented standard beats a generic smell.
- **The anchor misses the line**: verify every anchor before posting, because a comment on the wrong line discredits the rest.
- **The head moved**: confirm the head is still the SHA you reviewed, and say so in the general comment when it advanced.

**Done when** every finding has been reproduced, dropped, or corrected.

### 4. Write the comments (`writing-guidelines`, `writing-for-agents`)

One general comment per PR, and one inline comment per anchor:

- **General**: open with what the change delivers, name what blocks the merge, and close with the count per axis. Link the sibling PR when there is a pair.
- **Inline**: state what is wrong, cite the evidence from the file or the spec, and show the output. One subject per comment.

`writing-guidelines` governs the voice: active, concise, filler cut. `writing-for-agents` governs the cut, because agents read PR comments too: keep the sentences that change a decision, and phrase the ask positively, saying what to do.

**Done when** every sentence asserts a fact checked in step 3.

### 5. Post the comments (`bkt`)

Run this step when the fixed point came from a PR. Read what is already there first with `bkt pr comments <id> --repo <slug> --details`, then post:

```bash
bkt pr comment <id> --repo <slug> --text "$(cat <file.md>)"
bkt pr comment <id> --repo <slug> --file <path> --to-line <line> --text "$(cat <file.md>)"
```

`--to-line` is the line in the new file; a deleted file takes only `--from-line`.

**Done when** `bkt pr comments <id> --json` returns the anchors you intended.

### 6. Report the findings

Report `## Standards` and `## Spec` as separate sections, each ranked within itself. Give the count and the worst finding per axis: one winner picked across both axes collapses the separation.

When the fixed point is a bare ref, this report is the deliverable, each finding carrying its file and line.
