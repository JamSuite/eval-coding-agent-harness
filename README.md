# eval-coding-agent-harness

Tells a skill author whether an edit to a `SKILL.md` changed what a coding agent writes. It runs
the agent many times under conditions that differ only in the skill body, and reports the change
with its uncertainty and with the other explanations ruled out.

Hosts: Claude Code, Codex, OpenCode, Antigravity CLI and Muse Code. Engine: promptfoo.

Status: bootstrapping. See [`PROMPTS.md`](PROMPTS.md) for the build plan and progress.

## Setup

Open this folder in VS Code and choose **Reopen in Container**. Everything installs inside the
container. Then log in to each host:

| Host            | Login                                 |
| --------------- | ------------------------------------- |
| Claude Code     | `claude` then `/login`                |
| Codex           | `codex login`                         |
| OpenCode        | `opencode auth login`                 |
| Antigravity CLI | `agy` (interactive sign-in)           |
| Muse Code       | `muse login`, if it installed         |

Each login is kept in a Docker volume scoped to this repository, so it survives a rebuild.
