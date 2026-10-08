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

Each login is kept in a Docker volume scoped to this repository, so it survives a rebuild.

A tool under `.devcontainer/install/` can be reinstalled without a rebuild: run
`sh .devcontainer/install/<tool>.sh`, where `<tool>` is `shell_toolchain`, `shellspec`,
`beads_rust`, `codex`, `opencode`, `antigravity` or `muse`. Each does nothing when its tool is
already installed. Their tests run offline with `shellspec`.

## Quality gate

```sh
make check
```

This is the definition of done for every prompt and task, locally and in CI
([`.github/workflows/gate.yml`](.github/workflows/gate.yml)). It calls no model, needs no login and
takes about ten seconds. `make help` lists its parts:

| Target        | What it checks                                                                              |
| ------------- | ------------------------------------------------------------------------------------------- |
| `lint`        | `shellcheck` on every shell source; type-aware ESLint on every TypeScript source            |
| `typecheck`   | `tsc --noEmit`. Node runs `.ts` files directly by type stripping, so nothing is built       |
| `fmt-check`   | `shfmt` and prettier find nothing to reformat. `make fmt` fixes it                          |
| `test-ts`     | every `*.test.ts`, with `node --test`                                                       |
| `test-sh`     | every ShellSpec specfile under `sh`, `dash`, `ash`, `bash` and `ksh`                        |
| `check-beads` | approved specs and task beads agree, as `PROMPTS.md` → Tracking requires; reads no database |

## Installed versions

Read in the container on 2026-10-08. Every host answered a one-line prompt with its login.

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

## Host availability

- **OpenCode:** deferred until the core harness works with Claude Code, Codex, Antigravity CLI and
  Muse Code. It stays installed, and its login volume stays, so it can come back without a rebuild.
- **Muse Code:** Meta's product page lists macOS and Windows builds only, but the installer
  succeeds on Linux. Muse Code 1.4.4 is installed in this container.
- **Antigravity CLI:** `agy` 1.3.1 is installed in this container. Its download server sometimes
  serves the installer gzipped without saying so; `.devcontainer/install/lib.sh` decompresses it.
  Its login survives a rebuild: one made before the rebuild of 2026-10-08 still answered a prompt
  after it.

## License

[Apache License 2.0](LICENSE.md). See [`CONTRIBUTING.md`](CONTRIBUTING.md) to contribute.
