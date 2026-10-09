# Project layout

[⬑ Back to arch TOC](./index.md)

Where each kind of file goes, how it is named, and how to choose between TypeScript and shell.

## Folders

| Path                        | Holds                                                                                                               |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `src/`                      | The harness: a library and its command-line tool. One folder per subsystem, named after its spec                    |
| `src/host-adapters/<host>/` | One [adapter](glossary.md) per host, such as `src/host-adapters/claude-code/`. No other code in `src/` names a host |
| `scripts/`                  | Tooling for this repository, not part of the harness, such as `scripts/check-beads.ts`                              |
| `spec/`                     | ShellSpec specfiles, named after the script or folder each tests                                                    |
| `fixtures/`                 | Test fixtures: sample skills, cases, recorded host output, run records ([`testing.md`](testing.md))                 |
| `docs/arch/`                | How the project is built and used; [`index.md`](index.md) lists it                                                  |
| `docs/arch/decisions/`      | Architecture decision records                                                                                       |
| `docs/specs/`               | `00-harness/spec.md`, the global spec, and one `NN-name/spec.md` per subsystem                                      |
| `.devcontainer/`            | The container, `postCreate.sh`, and one install script per tool under `install/`                                    |
| `.github/workflows/`        | CI. `gate.yml` runs `make check`                                                                                    |
| `.beads/`                   | The tracker. `issues.jsonl` is committed; the database is not (`.beads/.gitignore`)                                 |
| `.claude/skills/beads-sdd/` | The skill for the Claude Code session that builds this repository. Never visible to a host under test               |

`src/` does not exist until the first BUILD prompt, `fixtures/` until P4 saves the first spike
output, and `docs/specs/` until P3. The subsystem
folders take the names in `PROMPTS.md` → Subsystems, without the number: `src/run-record/`,
`src/workspace-and-conditions/` and so on.

Experiments do not run inside this repository. Each run's workspace is created outside it, and
outside the reference repository and `/workspaces`, because hosts load instruction files from a
workspace's ancestors. `CLAUDE.md` → "Run workspaces never inherit this repository's instructions"
gives the rule.

## Naming

- TypeScript files are kebab-case: `check-beads.ts`. A test sits beside its code as
  `check-beads.test.ts`.
- Shell scripts are snake_case with a `.sh` extension: `shell_toolchain.sh`. `postCreate.sh` keeps
  the devcontainer convention. A specfile is `<name>_spec.sh` under `spec/`, where `<name>` is the
  script or folder it tests: `spec/devcontainer/install_spec.sh` tests `.devcontainer/install/`.
- Specs are `docs/specs/NN-name/spec.md`, with `NN` and `name` from `PROMPTS.md` → Subsystems.
- ADRs are `docs/arch/decisions/NNNN-title.md`, numbered from `0001` in the order they are written.

## TypeScript or shell

TypeScript is the default. Use a POSIX `sh` script only when it is shorter and plainer than the
TypeScript would be. That is the rule in `CLAUDE.md`; this section is how to apply it.

Choose shell for work that is mostly calling other programs and moving files: creating and
removing a workspace, copying a fixture into place, taking a snapshot of a directory, small glue
between commands. Shell files start with `#!/bin/sh` and `# shellcheck shell=sh`, use no bashisms,
and pass their specs under every shell the gate runs.

Choose TypeScript for anything that holds data or makes a decision: parsing JSON or a transcript,
building a run record, classifying an outcome, hashing, statistics, anything promptfoo calls, and
anything another module imports. Node is already required by promptfoo, so TypeScript adds no
runtime.

When a shell script grows a data structure, a loop over parsed fields, or a second level of
quoting, move it to TypeScript. When a TypeScript module is mostly `execFile` calls in sequence,
consider shell.
