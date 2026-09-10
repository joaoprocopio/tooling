# GitHub: `gh`, verified against gh 2.97.0

Match this adapter to a repo:

- **Hosts**: `github.com`, and a GitHub Enterprise host the user names.
- **Detect**: `git remote get-url origin` matches the host above, and `gh` is on PATH. On `command not found`, stop and tell the user `gh` is missing. On an auth error, report `gh auth status` and wait, rather than running a login command.

`gh` infers the repo from the working directory. Pass `-R <owner>/<repo>` explicitly whenever a command runs outside the PR's own checkout, which is every command on a **pair**. `gh` fills the `{owner}` and `{repo}` placeholders in an api path from the same inference, so they take the same care.

The PR argument is positional and optional on almost every `gh pr` subcommand, defaulting to the PR for the current branch. Pass it explicitly, so a step reviews the PR it named.

Anchors, threads, blockers, and the verdict live in [`github-feedback.md`](github-feedback.md), which `pr-review` and `pr-fix` load alongside this file.

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

A loop that posts one call per finding provokes the secondary rate limit, which returns 403 with a `Retry-After` header rather than a quota message. Batch the review per `github-feedback.md` to stay under it. On a 403, stop the loop and report what landed, per `pr`.

## Operations

| Operation         | Command                                                                                                                                                         |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pr.identity`     | `gh pr view <id> --json baseRefName,headRefName,headRefOid,body,title,url,isDraft,isCrossRepository,headRepository,headRepositoryOwner,state`                   |
| `pr.files`        | `gh pr view <id> --json changedFiles,additions,deletions,files`                                                                                                 |
| `pr.diff`         | `gh pr diff <id> --patch` (`--name-only` for the file list alone, `-e <glob>` to drop a generated file)                                                         |
| `pr.diff-line`    | not served, see `github-feedback.md`                                                                                                                            |
| `thread.list`     | `gh api graphql` on `reviewThreads`, see `github-feedback.md`                                                                                                    |
| `thread.create`   | `gh api --method POST repos/{owner}/{repo}/pulls/<id>/comments -f body="$(cat <body.md>)" -f commit_id=<head-sha> -f path=<file> -F line=<n> -f side=RIGHT`     |
| `thread.reply`    | `gh api --method POST repos/{owner}/{repo}/pulls/<id>/comments/<comment-databaseId>/replies -f body="$(cat <body.md>)"`                                         |
| `thread.resolve`  | `gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{id isResolved}}}' -f id=<thread-node-id>`                          |
| `thread.reopen`   | the same mutation as `unresolveReviewThread`                                                                                                                    |
| `blocker.list`    | `gh pr view <id> --json reviewDecision,latestReviews` plus the unresolved threads from `thread.list`                                                            |
| `blocker.create`  | not served, see `github-feedback.md`                                                                                                                            |
| `blocker.resolve` | `thread.resolve` on the thread that carries it                                                                                                                  |
| `checks.read`     | `gh pr checks <id> --json name,state,bucket,link,workflow,completedAt`                                                                                          |
| `checks.log`      | `gh run list -c <head-sha> -s failure --json databaseId,workflowName` then `gh run view <run-id> --log-failed`                                                  |
| `verdict`         | `gh pr review <id> --approve` / `--request-changes -F <verdict.md>` / `gh pr close <id> --comment "<reason>"`                                                   |
| `pr.create`       | `gh pr create --title "<title>" --base <branch> --head <branch> --body-file <file.md> [--reviewer <handle>]... [--draft]`                                       |
| `pr.update`       | `gh pr edit <id> --title "<title>" --body-file <file.md> [--base <branch>] [--add-reviewer <handle>]`, and `gh pr ready <id>` / `gh pr ready <id> --undo` for draft |
| `pr.reviewers`    | `gh pr view <id> --json reviewRequests,latestReviews`, plus `gh api repos/{owner}/{repo}/contents/.github/CODEOWNERS` for who the repo adds on its own          |
| `pr.queue`        | `gh pr status --json number,title,url,reviewDecision` or `gh pr list --search "review-requested:@me"`                                                           |

`pr.identity` reads the fields from these paths: target is `baseRefName`, source branch `headRefName`, head SHA `headRefOid`, description `body`. There is no single field for the source repo: `isCrossRepository` true means the source is a **forked repo**, and the repo is `headRepositoryOwner.login` joined to `headRepository.name`.

## Checks

`gh pr checks <id>` returns each check with a `state`, a `bucket` of `pass`, `fail`, `pending`, `skipping`, or `cancel`, and a `link`. **Exit code 8 means checks are still pending**, which is a result rather than an error: `--watch` waits for them once, with the ceiling `pr` sets, and `--required` narrows to the ones that gate the merge.

A failed check reads its log through the run, not the PR, per the `checks.log` row. `--log-failed` returns only the failing steps, where `--log` returns the whole run and costs the context that the finding needs.

## Not served

- **`pr.diff-line`**: no command maps text to a diff line. Compute it from the patch, per `github-feedback.md`.
- **`blocker.create`**: no task object. The `request-changes` verdict plus a labelled thread replaces it, per `github-feedback.md`.
- **Decline**: GitHub closes rather than declines, per the `verdict` row, and `gh pr reopen <id>` undoes it.
- **Checkout by the adapter**: `gh pr checkout <id>` exists, but the workflows fetch with `git` per `pr`, so that the branch a step edits is the one it chose.
- **Applying a suggestion**: no command applies one. `pr` describes the manual apply.
