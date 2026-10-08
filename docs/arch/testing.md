# Testing

How the harness's own code is tested. This is not about evaluating skills: an experiment runs a
model and costs money, while every test here runs without a model, a login or the network, and the
whole suite finishes in seconds.

## The gate

`make check` is the gate that every prompt and task must pass to be done, locally and in CI
(`.github/workflows/gate.yml`). It runs these targets, and stops at the first that fails:

| Target        | What it checks                                                                              |
| ------------- | ------------------------------------------------------------------------------------------- |
| `lint`        | `shellcheck` on every shell source; type-aware ESLint on every TypeScript source            |
| `typecheck`   | `tsc --noEmit`. Node runs `.ts` files directly by stripping types, so nothing is built      |
| `fmt-check`   | `shfmt` and prettier find nothing to reformat. `make fmt` fixes it                          |
| `test-ts`     | every `*.test.ts` outside `node_modules`, with `node --test`                                |
| `test-sh`     | every ShellSpec specfile under `sh`, `dash`, `ash`, `bash` and `ksh`; a missing shell fails |
| `check-beads` | approved specs and task beads agree, as `PROMPTS.md` → Tracking requires                    |

`check-beads` reads the committed `.beads/issues.jsonl`, not the beads database, so CI needs no
`br`. It fails when an approved spec has a task with no bead, when a `spec-NN` bead names a task
its spec does not have, or when a closed BUILD bead has open task beads.

To run one slice:

```sh
node --test scripts/check-beads.test.ts      # one TypeScript test file
shellspec spec/devcontainer/install_spec.sh  # one specfile, under /bin/sh
shellspec --shell ksh                        # every specfile, under one shell
```

## Test first

Write the test, run it and watch it fail, then write the code. A test that has never failed has
not shown that it can. When it helps a reviewer, commit the failing test on its own first, as
commits `6a5ffbf` and `4b40e1a` do for `scripts/check-beads.ts`.

## Seeded-breakage tests

Every [control](controls.md) has a test that creates the exact breakage the control exists to
catch and checks that the control catches it. A test that only feeds the control good input shows
that it passes clean runs, which a control that does nothing also does.

For example, a test of the preflight plants an `AGENTS.md` two directories above a workspace and
expects the run to be refused. A test of the read-scope check gives it a transcript with a read
outside the workspace and expects an exclusion. A second one gives it the same read refused by the
permission rule and expects none.

Fail-closed checks need one more case each: the input the check cannot read. Point it at a missing
file, an unreadable file and an empty file, and expect a violation or `error`, never a match.

## Fixtures

Fixtures live under `fixtures/`, grouped by what they stand in for: a sample skill, a case, a host's
raw output, a run record.

- **Recorded host output.** Tests of an adapter read output that a real host produced once and was
  saved as a fixture, so they need no login. P4 saves the first of these.
- **The reference runs.** The 84 run records in the reference repository's `eval/runs/` may be
  copied in as fixtures, for their shape. They are never a side of a comparison.
- **Instruction files and skills.** A fixture `CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md` or
  `GEMINI.md` is kept under `fixtures/` with a `.fixture` suffix, such as `AGENTS.md.fixture`, and
  the test copies it into a temporary directory under its real name. A sample skill is kept as
  `fixtures/skills/<name>/SKILL.md`, never under `.claude/`, `.agents/`, `.codex/` or
  `.opencode/`, and is copied into the host's skill location the same way. Under their real names
  and locations, the Claude Code session that builds this repository would load them.

A test that needs a workspace makes one under the system temporary directory, outside this
repository, and removes it afterwards.

## Shell tests

Shell is tested with ShellSpec. Specfiles live under `spec/`, mirroring the path of the script
they test, and end in `_spec.sh`. Each one runs under every shell `test-sh` lists. Stubs for
external commands, such as `curl` or a host CLI, go first on `PATH`, so a spec never reaches the
network; `spec/devcontainer/install_spec.sh` shows the pattern.
