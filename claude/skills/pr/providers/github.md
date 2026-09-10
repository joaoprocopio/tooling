# GitHub: `gh`, verified against gh 2.97.0

Match this adapter to a repo:

- **Hosts**: `github.com`, and a GitHub Enterprise host the user names.
- **Detect**: `git remote get-url origin` matches the host above, and `gh` is on PATH. On `command not found`, stop and tell the user `gh` is missing. On an auth error, report `gh auth status` and wait, rather than running a login command.

`gh` infers the repo from the working directory. Pass `-R <owner>/<repo>` explicitly whenever a command runs outside the PR's own checkout, which is every command on a **pair**. `gh` fills the `{owner}` and `{repo}` placeholders in an api path from the same inference, so they take the same care.

The PR argument is positional and optional on almost every `gh pr` subcommand, defaulting to the PR for the current branch. Pass it explicitly, so a step reviews the PR it named.

## Two APIs

`gh` serves the identity, the diff, the general comment, the verdict, and the checks. Everything about an **anchored** comment goes through `gh api`, and thread resolution goes through GraphQL, which is a third shape again. Three id spaces meet here, so keep them straight:

- **PR number**: what every `gh pr` command takes.
- **Comment `databaseId`**: the REST id of the comment that opens a thread, which is what a reply targets.
- **Thread node id**: the GraphQL id of the thread, which is what resolution takes.

One `thread.list` query returns the last two together, so read it once and carry both.

## Output

`--json <fields>` returns JSON on stdout, and `-q` filters it with jq. A large payload goes to a file the step reads, rather than through stdout:

```bash
gh pr view <id> --json <fields> > pr.json
gh api --paginate repos/{owner}/{repo}/pulls/<id>/comments > comments.json
```

`gh api` flags: `-f key=value` sends a string, `-F key=value` sends a typed value, so a line number takes `-F` and a path takes `-f`. Any field flag turns the request into a POST unless `--method` says otherwise.

## Rate limits

A loop that posts one call per finding provokes the secondary rate limit, which returns 403 with a `Retry-After` header rather than a quota message. Batch the review per **Batched review** to stay under it. On a 403, stop the loop and report what landed, per `pr`.

## Operations

| Operation         | Command                                                                                                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pr.identity`     | `gh pr view <id> --json baseRefName,headRefName,headRefOid,body,title,url,isDraft,isCrossRepository,headRepository,headRepositoryOwner,state`                       |
| `pr.files`        | `gh pr view <id> --json changedFiles,additions,deletions,files`                                                                                                     |
| `pr.diff`         | `gh pr diff <id> --patch` (`--name-only` for the file list alone, `-e <glob>` to drop a generated file)                                                             |
| `pr.diff-line`    | not served, see **Anchors**                                                                                                                                         |
| `thread.list`     | `gh api graphql` on `reviewThreads`, see **Threads**                                                                                                                |
| `thread.create`   | `gh api --method POST repos/{owner}/{repo}/pulls/<id>/comments -f body="$(cat <body.md>)" -f commit_id=<head-sha> -f path=<file> -F line=<n> -f side=RIGHT`         |
| `thread.reply`    | `gh api --method POST repos/{owner}/{repo}/pulls/<id>/comments/<comment-databaseId>/replies -f body="$(cat <body.md>)"`                                             |
| `thread.resolve`  | `gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{id isResolved}}}' -f id=<thread-node-id>`                              |
| `thread.reopen`   | the same mutation as `unresolveReviewThread`                                                                                                                        |
| `blocker.list`    | `gh pr view <id> --json reviewDecision,latestReviews` plus the unresolved threads from `thread.list`                                                                |
| `blocker.create`  | not served, see **Blockers**                                                                                                                                        |
| `blocker.resolve` | `thread.resolve` on the thread that carries it                                                                                                                      |
| `checks.read`     | `gh pr checks <id> --json name,state,bucket,link,workflow,completedAt`                                                                                              |
| `checks.log`      | `gh run list -c <head-sha> -s failure --json databaseId,workflowName` then `gh run view <run-id> --log-failed`                                                      |
| `verdict`         | `gh pr review <id> --approve` / `--request-changes -F <verdict.md>` / `gh pr close <id> --comment "<reason>"`                                                       |
| `pr.create`       | `gh pr create --title "<title>" --base <branch> --head <branch> --body-file <file.md> [--reviewer <handle>]... [--draft]`                                           |
| `pr.update`       | `gh pr edit <id> --title "<title>" --body-file <file.md> [--base <branch>] [--add-reviewer <handle>]`, and `gh pr ready <id>` / `gh pr ready <id> --undo` for draft |
| `pr.reviewers`    | `gh pr view <id> --json reviewRequests,latestReviews`, plus `gh api repos/{owner}/{repo}/contents/.github/CODEOWNERS` for who the repo adds on its own              |
| `pr.queue`        | `gh pr status --json number,title,url,reviewDecision` or `gh pr list --search "review-requested:@me"`                                                               |

`pr.identity` reads the fields from these paths: target is `baseRefName`, source branch `headRefName`, head SHA `headRefOid`, description `body`. There is no single field for the source repo: `isCrossRepository` true means the source is a **forked repo**, and the repo is `headRepositoryOwner.login` joined to `headRepository.name`.

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

## Checks

`gh pr checks <id>` returns each check with a `state`, a `bucket` of `pass`, `fail`, `pending`, `skipping`, or `cancel`, and a `link`. **Exit code 8 means checks are still pending**, which is a result rather than an error: `--watch` waits for them once, with the ceiling `pr` sets, and `--required` narrows to the ones that gate the merge.

A failed check reads its log through the run, not the PR, per the `checks.log` row. `--log-failed` returns only the failing steps, where `--log` returns the whole run and costs the context that the finding needs.

## Not served

- **`pr.diff-line`**: no command maps text to a diff line. Compute it from the patch, per **Anchors**.
- **`blocker.create`**: no task object. The `request-changes` verdict plus a labelled thread replaces it, per **Blockers**.
- **Decline**: GitHub closes rather than declines, per the `verdict` row, and `gh pr reopen <id>` undoes it.
- **Checkout by the adapter**: `gh pr checkout <id>` exists, but the workflows fetch with `git` per `pr`, so that the branch a step edits is the one it chose.
- **Applying a suggestion**: no command applies one. `pr` describes the manual apply.
