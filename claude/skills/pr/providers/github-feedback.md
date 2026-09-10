# GitHub: anchors, threads, blockers, and the verdict

The half of the GitHub adapter that `pr-review` and `pr-fix` load. `pr-open` does not. Commands live in the Operations table in [`github.md`](github.md); this file carries what a table cell cannot.

## Anchors

`thread.create` takes the anchor as parameters on the review-comment endpoint, and they are the four the contract names:

- `-f path=<file> -F line=<n> -f side=RIGHT`: new side, the added or destination side, and the default.
- `-f path=<file> -F line=<n> -f side=LEFT`: old side; a deleted file takes only this.
- `-f path=<file> -F start_line=<a> -f start_side=RIGHT -F line=<b> -f side=RIGHT`: a range whose end is `line`, which is what a multi-line suggestion takes.
- no `path`: general, which is `gh pr comment <id> --body-file <file.md>` rather than the review-comment endpoint.

`-f subject_type=file` with a `path` and no `line` anchors to a whole file.

Every anchored post takes `commit_id`, and it must be the head SHA `pr.identity` returned. A stale SHA is the common rejection: re-read the head before re-anchoring.

### `pr.diff-line`

Nothing on GitHub maps a piece of text to the line the diff carries, so the adapter computes it. Read the full patch **once** into a file and resolve every anchor in the review against that one file:

```bash
gh pr diff <id> --patch > patch.diff
```

Each hunk opens with `@@ -<old-start>,<old-count> +<new-start>,<new-count> @@`. Walk the body from that header. For the **new side**, start at `<new-start>` and count every `+` and context line. For the **old side**, start at `<old-start>` and count every `-` and context line. The line whose text matches carries the number to anchor on. A `\ No newline at end of file` marker counts as nothing.

Match on the anchor text, per `pr`. One fetch per finding re-pays the whole patch's token cost, so the file is the budget.

## Threads

A review comment with no `in_reply_to` opens a thread; every other one hangs off it. Resolution takes the thread's GraphQL node id, which is a different id from the comment's, so read both from one query:

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$number:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$number){
      reviewThreads(first:100){
        nodes{ id isResolved isOutdated path line startLine originalLine
               comments(first:50){ nodes{ databaseId author{login} body } } } } } } }' \
  -f owner=<owner> -f repo=<repo> -F number=<id>
```

A thread is **live** when `isResolved` is false. `isOutdated` true means the head moved past its anchor, which is drift and takes a re-anchor. `id` resolves the thread; `comments.nodes[0].databaseId` is what a reply targets.

`gh api --paginate repos/{owner}/{repo}/pulls/<id>/comments` lists the same comments over REST, faster and with no resolution state. It answers what is anchored where, and leaves what is still open to the GraphQL query.

## Blockers

GitHub has no task object. It carries a blocker two ways, and an adapter uses both:

- **The verdict blocks.** `gh pr review <id> --request-changes` gates the merge under branch protection until the reviewer clears it, which is the real equivalent of a Bitbucket task.
- **An unresolved thread blocks**, where the repo requires conversation resolution before merge.

So `blocker.create` is the `request-changes` verdict plus the thread that carries the evidence, `blocker.list` is the standing review decision plus the unresolved threads, and `blocker.resolve` is resolving that thread. A markdown checkbox in a comment body gates nothing and is not a blocker.

Since the verdict is the user's, a step that raises a blocker names the finding as blocking and leaves the `request-changes` command to them.

## Batched review

`POST repos/{owner}/{repo}/pulls/<id>/reviews` takes a `comments[]` array with a body and an `event` of `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`, which posts a whole review at once instead of one comment per call:

```bash
gh api --method POST repos/{owner}/{repo}/pulls/<id>/reviews --input review.json
```

**This is the default on GitHub.** Every comment in the array carries its own `path`, `line`, and `side`, and one rejected anchor rejects the whole review, so batching is safe exactly when every anchor has been confirmed through `pr.diff-line`, which `pr-review` step 3 does for every finding before step 5 posts. One call also stays under the secondary rate limit that a per-finding loop provokes.

A rejected batch falls back to posting per finding: the rejection names the bad anchor, so drop that comment to a general one and re-send the rest.

## Verdict

A body is optional on `--approve` and **required** on `--request-changes` and `--comment`. So the reason rides inside the verdict, where Bitbucket needs a general comment first. `-F -` reads it from stdin.

GitHub has no `unapprove`. A standing review is withdrawn by dismissing it through `PUT repos/{owner}/{repo}/pulls/<id>/reviews/<review-id>/dismissals`, which takes a message.
