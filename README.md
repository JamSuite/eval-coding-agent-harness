# eval-coding-agent-harness

Tells a skill author whether an edit to a `SKILL.md` changed what a coding agent writes. It runs
the agent many times under conditions that differ only in the skill body, and reports the change
with its uncertainty and with the other explanations ruled out.

The hosts it targets, and their order, are in [`PROMPTS.md`](PROMPTS.md) → Shared context → Hosts.
Engine: promptfoo.

[`PROMPTS.md`](PROMPTS.md) holds the build plan; progress is tracked in beads
(`br ready --label prompt`). [`docs/arch/spec-process.md`](docs/arch/spec-process.md) describes a
working session.

## Setup and usage

- [`docs/arch/setup.md`](docs/arch/setup.md): open the devcontainer, log in to each host, run the
  gate.
- [`docs/arch/usage.md`](docs/arch/usage.md): run an experiment.
- [`docs/arch/toc.md`](docs/arch/toc.md): everything else under `docs/`.

## Quality gate

```sh
make check
```

Every prompt and task must pass it to be done, locally and in CI. It calls no model and needs no
login. [`docs/arch/testing.md`](docs/arch/testing.md) says what it checks.

## Installed versions

Read in the container on 2026-10-08. Every host except OpenCode, which is
deferred, answered a one-line prompt with its login.
[`docs/arch/setup.md`](docs/arch/setup.md) → Host notes explains the Claude Code and Codex rows.

| Tool            | Version                                                                               |
| --------------- | ------------------------------------------------------------------------------------- |
| Node            | 24.21.0                                                                               |
| promptfoo       | 0.124.1                                                                               |
| Claude Code     | 2.1.295. It updates itself, so this changes without a rebuild                         |
| Codex           | 0.162.0 on PATH; promptfoo's `openai:codex-sdk` brings 0.156.1 in `node_modules/.bin` |
| Antigravity CLI | 1.3.1                                                                                 |
| Muse Code       | 1.4.4                                                                                 |
| OpenCode        | 1.18.35; deferred, not checked                                                        |
| br              | 0.7.4                                                                                 |
| ShellSpec       | 0.28.1                                                                                |
| TypeScript      | 6.0.3, the newest below 6.1, which is as far as typescript-eslint 8.71.1 allows       |

## License

[Apache License 2.0](LICENSE.md). See [`CONTRIBUTING.md`](CONTRIBUTING.md) to contribute.
