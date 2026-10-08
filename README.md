# eval-coding-agent-harness

Tells a skill author whether an edit to a `SKILL.md` changed what a coding agent writes. It runs
the agent many times under conditions that differ only in the skill body, and reports the change
with its uncertainty and with the other explanations ruled out.

Hosts: Claude Code, Codex, OpenCode, Antigravity CLI and Muse Code. Engine: promptfoo.

Status: bootstrapping. [`PROMPTS.md`](PROMPTS.md) holds the build plan; progress is tracked in beads
(`br ready --label prompt`). [`docs/arch/spec-process.md`](docs/arch/spec-process.md) describes a
working session.

## Setup

Open this folder in VS Code and choose **Reopen in Container**. Everything installs inside the
container. Then log in to each host:

| Host            | Login                           |
| --------------- | ------------------------------- |
| Claude Code     | `claude` then `/login`          |
| Codex           | `codex login`                   |
| OpenCode        | deferred; `opencode auth login` |
| Antigravity CLI | `agy` (interactive sign-in)     |
| Muse Code       | `muse login`                    |

Each login except Antigravity's is kept in a Docker volume scoped to this repository, so it
survives a rebuild. For Antigravity, see Host availability.

A tool fetched with curl can be reinstalled without a rebuild: run
`sh .devcontainer/install/<tool>.sh`, where `<tool>` is `beads_rust`, `shellspec`, `codex`,
`antigravity` or `muse`. Each does nothing when its tool is already installed. Their tests run
offline with `shellspec`.

## Host availability

- **OpenCode:** deferred until the core harness works with Claude Code, Codex, Antigravity CLI and
  Muse Code. It stays installed, and its login volume stays, so it can come back without a rebuild.
- **Muse Code:** Meta's product page lists macOS and Windows builds only, but the installer
  succeeds on Linux. Muse Code 1.4.4 is installed in this container.
- **Antigravity CLI:** `agy` 1.3.1 is installed in this container. Its download server sometimes
  serves the installer gzipped without saying so; `.devcontainer/install/lib.sh` decompresses it.
  Antigravity keeps its login in the OS keyring, and the container has none, so whether the login
  survives a rebuild is still unproven.

## License

[Apache License 2.0](LICENSE.md). See [`CONTRIBUTING.md`](CONTRIBUTING.md) to contribute.
