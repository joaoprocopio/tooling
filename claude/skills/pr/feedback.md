# Review feedback mechanics

The half of `pr` that only reviewing a change and working its feedback reach. `pr-review` and `pr-fix` read it after `pr`; `pr-open` does not.

## Anchors

An **anchor** is a file and a line, in one of four shapes:

- **New side**: a line the diff adds, which is what a suggestion takes
- **Old side**: a line the diff removes, which is all a deleted file takes
- **Range**: several lines on the new side, for a suggestion replacing more than one
- **General**: no anchor at all, which is where the summary and the merge blockers go

An anchor holds only on a line the diff carries, and its number comes from `pr.diff-line`. **Anchor text** is what `pr.diff-line` takes: the distinctive text of the line, appearing once in the file, with the file path. Text that matches more than once has no anchor: narrow it, or take the finding to a general comment. A number read off the local file is the wrong number whenever the head moves or the hunk shifts.

A finding about a line outside every hunk goes in a general comment naming the file and line in its text. A rejected post is the server refusing the anchor: re-run `pr.diff-line` and re-anchor.

## Threads

A thread is one subject: the finding, its evidence, and the replies under it. A thread is **live** while the forge reports it unresolved, and `thread.list` is what the fix loop reads.

Two rules hold on every forge:

- **A thread ID is the ID of the comment that opens it.** Replies hang off that ID, and resolution takes it.
- **One subject per thread.** A second subject is a second `thread.create`, so the author can resolve each one on its own.

## Suggestions

Write a suggestion by fencing the replacement lines in the body, which gives the author a one-click apply on every forge that renders it:

````text
```suggestion
const timeout = 30_000
```
````

The fence replaces the anchored lines, so anchor it to exactly the lines it replaces and keep the block to what changes.

Apply one that came the other way by editing the anchored lines yourself: read the anchor, confirm those lines still hold the code the suggestion replaces, and put the fenced block in their place.

## Blockers

A **blocker** is a finding that gates the merge. It takes both halves: the thread carries the evidence, and one line names the change that unblocks it. An adapter with first-class tasks raises a task against the thread; an adapter without them raises the merge block through its verdict. `blocker.list` is what a later step closes each one against.

## Verdict

The verdict is **approve**, **request changes**, or **decline**, and it is the reviewer's terminal act. It belongs to the user: state the verdict you would give and let the user run the command.
