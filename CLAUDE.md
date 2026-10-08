# eval-coding-agent-harness

`PROMPTS.md` holds the build plan; read its Shared context before any prompt. Track work with
`br` using the commands in `.claude/skills/beads-sdd/SKILL.md`.

## Rules

- **Language.** TypeScript by default; POSIX `sh` when shorter and plainer. Shell files start with
  `#!/bin/sh` and `# shellcheck shell=sh`, and contain no bashisms.
- **Test first.** Write the test, watch it fail, then implement. Every control gets a test that
  seeds the breakage it detects. Unit tests never call a model or need a login.
- **Spec first.** Write no harness code without an approved spec under `docs/specs/`.
- **Done.** The quality gate, `make check`, passes; the work is committed; and its bead is closed
  with the commit hash.
- **Scope.** Do what the prompt asks; record anything else as a `spec-NN` or `harness` bead.
- **Reference repository.** `/workspaces/coding-agent-skills-tdd` is read-only. Build from it; do
  not copy it.

## Run workspaces never inherit this repository's instructions

Hosts load `CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md` and `GEMINI.md` from a workspace and its
ancestors, and skills from `.claude/`, `.agents/`, `.codex/` and `.opencode/`. A run that loads
this file is contaminated.

- Create run workspaces outside this repository, the reference repository and `/workspaces`. No
  ancestor of a workspace may hold any of the files or directories above.
- Keep `CLAUDE.md` and `AGENTS.md` at this repository's root only; never in a shared parent such
  as `/`, `/workspaces`, `/tmp` or `$HOME`.
- A fixture that needs one of these files keeps it under test fixtures and copies it in.
