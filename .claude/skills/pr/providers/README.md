# Provider adapters

One file per forge, named for the host in the git remote: `github.md`, `bitbucket.md`, `gitlab.md`. `pr` loads the matching one and runs attached; no match means detached, and every workflow still completes.

An adapter is a table, nothing more. It maps each operation in the contract to that forge's CLI and declares the ones it cannot serve, so the workflows never name a command.

```markdown
# <forge> — <cli> <version tested>

Hosts: github.com, *.ghe.example
Detect: `git remote get-url origin` matches the hosts above.

| Operation | Command |
|---|---|
| `pr.identity` | `gh pr view <id> --json ...` |
| `pr.diff` | `gh pr diff <id>` |
| ... | ... |

## Not served

- `blocker.list` — no first-class tasks. Blockers go through the verdict instead.
```

Three rules keep an adapter honest:

- **Ask for JSON**, write it to a stable path, and read that file, rather than parsing a human table.
- **Declare the gaps.** An operation the forge cannot serve is listed under `## Not served` with the fallback that replaces it. An operation missing from both tables is a bug in the adapter, not a reason to skip a step.
- **Name the repo explicitly** on every command that runs outside the checkout, which is every command on a pair.
