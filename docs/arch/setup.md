# Setup

[⬑ Back to arch TOC](./index.md)

How to get from a fresh clone to a passing gate. Everything runs inside the devcontainer; nothing
is installed on the host machine.

## 1. Open the devcontainer

Clone this repository next to `coding-agent-skills-tdd`, the reference repository; the container
bind-mounts it read-only from `../coding-agent-skills-tdd`. Open this folder in VS Code and choose
**Reopen in Container**.

`.devcontainer/postCreate.sh` installs every tool, using one script per tool under
`.devcontainer/install/`. To reinstall one without a rebuild, run
`sh .devcontainer/install/<tool>.sh`, where `<tool>` is `shell_toolchain`, `shellspec`,
`beads_rust`, `codex`, `opencode`, `antigravity` or `muse`. Each does nothing when its tool is
already installed. `spec/devcontainer/install_spec.sh` tests them offline.

The README records the version of every tool the container installed.

## 2. Log in to each host

| Host            | Login                       | Check that it works                              |
| --------------- | --------------------------- | ------------------------------------------------ |
| Claude Code     | `claude`, then `/login`     | `claude -p 'Reply with exactly the word: pong'`  |
| Codex           | `codex login`               | `codex exec 'Reply with exactly the word: pong'` |
| Antigravity CLI | `agy` (interactive sign-in) | `agy -p 'Reply with exactly the word: pong'`     |
| Muse Code       | `muse login`                | `muse exec 'Reply with exactly the word: pong'`  |
| OpenCode        | `opencode auth login`       | deferred; see Host notes                         |

Run the checks from an empty directory outside this repository, so that no host loads this
repository's `CLAUDE.md` or `AGENTS.md`. Outside a git repository, `codex exec` also needs
`--skip-git-repo-check`.

Each login is kept in a Docker volume scoped to this repository, so it survives a rebuild. No other
repository's container sees these volumes.

## 3. Run the gate

```sh
make check
```

It needs no login. [`testing.md`](testing.md) says what it
checks.

## Host notes

- **Claude Code** updates itself. Its version can change between two runs without a rebuild.
- **Codex:** `.devcontainer/install/codex.sh` puts a pinned release on `PATH`. promptfoo brings an
  older one into `node_modules/.bin`, which its `openai:codex-sdk` provider drives unless told
  otherwise.
- **Antigravity CLI:** its download server sometimes serves the installer gzipped without saying
  so; `.devcontainer/install/lib.sh` decompresses it. The container has no OS keyring, yet the
  login survives a rebuild.
- **Muse Code:** Meta's product page lists macOS and Windows builds only, but the installer
  succeeds on Linux.
- **OpenCode** is deferred (`PROMPTS.md` → Shared context → Hosts). It stays installed, and its login volume stays, so it can come back without a
  rebuild.
