# Provider adapters

One file per forge, named for the host in the git remote: `github.md`, `bitbucket.md`, and whatever a new forge is called. `pr` loads the file whose hosts match the remote. No match means the workflow stops and asks the user which forge to use, since every review operation runs through an adapter.

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

Five rules keep an adapter honest:

- **Ask for JSON**, write it to a stable path, and read that file, rather than parsing a human table.
- **Declare the gaps.** An operation the forge cannot serve is listed under `## Not served` with the fallback that replaces it, written out far enough to run. An operation missing from both tables is a bug in the adapter, not a reason to skip a step.
- **Serve every row.** A command that serves two operations appears on both rows, saying so. Two operations that look alike on one forge are separate on another, and the contract keeps them apart for that forge's sake.
- **Name the repo explicitly** on every command that runs outside the checkout, which is every command on a pair.
- **Say which ids the forge uses.** A thread id, a comment id, and a task id are three different things on Bitbucket, and a comment's REST id and its thread's GraphQL id are two different things on GitHub. An adapter that leaves this implicit produces posts the server rejects.

Verify against a version and name it in the heading. A flag that moved between releases is the failure an adapter exists to absorb.
