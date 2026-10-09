# Contents of `docs/`

## Getting started

- [`setup.md`](setup.md): the devcontainer, the login for each host, and the first gate run.
- [`usage.md`](usage.md): how to run an experiment, from definition to verdict.
- [`glossary.md`](glossary.md): the terms every other document uses.

## How the harness is built

- [`controls.md`](controls.md): each rival explanation and the control that rules it out.
- [`project-layout.md`](project-layout.md): folders, naming, and when to use TypeScript or shell.
- [`testing.md`](testing.md): the gate, test-first work, seeded-breakage tests and fixtures.
- [`decisions/`](decisions/README.md): architecture decision records.

## How the work is run

- [`spec-process.md`](spec-process.md): how specs are written, reviewed and tracked to done, and
  what a working session looks like.
- [`writing-style.md`](writing-style.md): the voice rules for every document.
- `docs/specs/`: the global spec and one spec per subsystem, in build order. Added by
  P3.

The rules for the whole project are in [`PROMPTS.md`](../../PROMPTS.md) → Shared context. The
commands for tracking work with `br` are in `.claude/skills/beads-sdd/SKILL.md`.
