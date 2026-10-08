# eval-coding-agent-harness

A library and command-line tool that runs a coding agent many times under conditions that differ
only in a skill's body, then reports how much the output moved, with its uncertainty, and with the
rival explanations ruled out. promptfoo is the engine; control logic stays independent of it. The
harness ships no skill; a sample skill exists only as a test fixture.

`PROMPTS.md` holds the build plan, the shared context (hosts, reference repository, rivals) and
the status tracker. Read its Shared context before any prompt.

## Rules

- **Language.** TypeScript by default. A POSIX `sh` script when it is shorter and plainer than the
  TypeScript: file and process work, snapshots, small glue. Shell files start with `#!/bin/sh` and
  `# shellcheck shell=sh`, and contain no bashisms.
- **Test first.** Write the test, watch it fail, then implement. Every control gets a test that
  seeds the breakage it detects. Unit tests never call a model or need a login.
- **Spec first.** Write no harness code without an approved spec under `docs/specs/`.
- **Done.** A task is done when the quality gate passes, the work is committed, and the status
  table in `PROMPTS.md` is updated. P1 creates the gate and names its command here.
- **Scope.** Do what the prompt asks. Record anything else under Open Questions in the relevant
  spec, or as a Note in the status table.
- **Writing.** Docs follow `docs/arch/writing-style.md` once it exists: plain, specific,
  checkable, with each fact stated once.
- **Reference repository.** `/workspaces/coding-agent-skills-tdd` is read-only. Build from it; do
  not copy it.

## Run workspaces never inherit this repository's instructions

Every host loads instruction files from the working directory and its ancestors (`CLAUDE.md`,
`CLAUDE.local.md`, `AGENTS.md`, `GEMINI.md`) and skills from directories such as `.claude/`,
`.agents/`, `.codex/` and `.opencode/`. A run that loads this file is contaminated.

- Create run workspaces outside this repository, outside the reference repository, and outside
  `/workspaces`. No ancestor of a workspace may hold any of the files or directories above.
- Keep `CLAUDE.md` and `AGENTS.md` at this repository's root only. Never write them to `/`,
  `/workspaces`, `/tmp`, `$HOME` or any other shared parent.
- A fixture that needs one of these files keeps it under a test fixtures directory and copies it
  into a workspace explicitly.
