# Bitbucket: anchors, threads, blockers, and the verdict

The half of the Bitbucket adapter that `pr-review` and `pr-fix` load. `pr-open` does not. Commands live in the Operations table in [`bitbucket.md`](bitbucket.md); this file carries what a table cell cannot.

## Anchors

`comment create` takes the anchor flags directly, and they are the four the contract names:

- `--path <file> --line <n>`: new side, the added or destination side.
- `--path <file> --from-line <n>`: old side; a deleted file takes only this.
- `--path <file> --start-line <a> --end-line <b>`: a range on the new side, which is what a multi-line suggestion takes. `--start-from-line`/`--end-from-line` is the old-side range.
- no `--path`: general.

Bitbucket serves `pr.diff-line` first-class, so every anchor number comes from that command rather than from a local read.

## Threads

Every comment write takes `--comment <id>`, and resolution takes the **top-level** comment's ID, so a thread ID is the ID of the comment that opens the thread. Replies cannot be resolved, reopened, or replied to.

In `comment query` output, each comment holds its anchor in `inline.path`, `inline.to`, and `inline.from`, and `parent.id` when it is a reply. `resolution` is a non-empty object when the thread is resolved; `deleted` and `pending` are flags. A thread is **live** when its opening comment has no `parent`, is not `deleted`, and carries an empty `resolution`.

## Blockers

Bitbucket serves blockers first-class, so a blocker becomes a real task rather than a line in a comment. A task is its own object with its own ID, attached to a thread through `--comment <thread-id>` or standing alone.

A task ID differs from the thread ID it hangs off. `--task` takes the task ID, and `task query` is where a step reads it. A blocker takes both halves: the inline thread carries the finding and the evidence, and the task carries the one-line ask that gates the merge.

`task update --resolve` and `--reopen` duplicate the dedicated verbs; prefer `task resolve` and `task reopen`, which say what they do. `task reopen --pull-request <id> --task <task-id>` revives one closed early.

## Posting

There is no batched review. `comment create --pending` holds a comment as draft feedback, and `twg` has no command that submits it: a pending comment stays invisible until someone finishes the review in the Bitbucket web UI. So post comments outright, one call per finding, unless the user asks for a draft and accepts that hand-off.

## Verdict

`approve`, `request-changes`, and `decline` take no text, so the reason goes in a general comment posted first. `unapprove` and `remove-request-changes` withdraw one.
