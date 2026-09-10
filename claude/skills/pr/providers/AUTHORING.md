# Writing a provider adapter

For a human adding a forge. No workflow loads this file.

An adapter is two files per forge, named for the host in the git remote:

- `<forge>.md`: identity, files, diff, checks, create, update, reviewers, queue. Every workflow loads it.
- `<forge>-feedback.md`: anchors, threads, blockers, verdict. `pr-review` and `pr-fix` load it; `pr-open` does not.

Add the host to the table in `pr/SKILL.md` under **The forge**, which is what routes a remote to an adapter.

An adapter is a table, nothing more. It maps each operation in the contract to that forge's CLI and declares the ones it cannot serve, so the workflows never name a command.

```markdown
# <forge>: <cli>, verified against <version>

This adapter serves two things:

- **Hosts**: <host>, <other host>
- **Detect**: `git remote get-url origin` matches the hosts above, and `<cli>` is on PATH.

| Operation     | Command                |
| ------------- | ---------------------- |
| `pr.identity` | `<cli> ... --json ...` |
| `pr.diff`     | `<cli> ...`            |
| `thread.list` | `<cli> ...`            |

## Not served

- `blocker.create`: no task object. The request-changes verdict plus a labelled thread replaces it.
```

Six rules keep an adapter honest:

- **Ask for JSON**, write it to a stable path, and read that file, rather than parsing a human table.
- **Declare the gaps.** An operation the forge cannot serve is listed under `## Not served` with the fallback that replaces it, written out far enough to run. An operation missing from both tables is a bug in the adapter, not a reason to skip a step.
- **Serve every row.** A command that serves two operations appears on both rows, saying so. Two operations that look alike on one forge are separate on another, and the contract keeps them apart for that forge's sake.
- **Name the repo explicitly** on every command that runs outside the checkout, which is every command on a pair.
- **The table owns the commands.** Prose under a heading carries what a table cell cannot: an id space, an algorithm, an exit code, an output envelope. A command written out twice goes stale in one of the two places.
- **Say which ids the forge uses.** A thread id, a comment id, and a task id are three different things on Bitbucket, and a comment's REST id and its thread's GraphQL id are two different things on GitHub. An adapter that leaves this implicit produces posts the server rejects.

Verify against a version and name it in the heading. A flag that moved between releases is the failure an adapter exists to absorb.
