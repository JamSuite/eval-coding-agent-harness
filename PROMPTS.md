<!--
WHAT THIS FILE IS
An ordered series of prompts that builds a standalone, reusable harness for evaluating
coding-agent skills under several coding-agent hosts. The prompts run one at a time in a Claude
Code session, and each one leaves the repo ready for the next.

WHERE IT LIVES
Written in coding-agent-skills-tdd. P0 copies it into the new repo as PROMPTS.md; P0B replaces
that copy with this version. After P0B, PROMPTS.md in the new repo holds the instructions and
beads (`br`) holds all status. Update only the new repo's copy.

HOW TO RESUME
Open Claude Code in the new repo and say:
    Run the next prompt from PROMPTS.md.
The session runs `br ready`, takes the ready prompt bead with the lowest prompt ID, reads that
prompt in PROMPTS.md, and runs only that one.

Exception: a repo whose P0 ran before P0B existed has an old PROMPTS.md. Start it with:
    Read /workspaces/coding-agent-skills-tdd/EVAL_HARNESS_PROJECT_PROMPTS.md and run P0B.

HOW TO UPDATE STATUS
Status lives only in beads; the rules are in Shared context → Tracking. There is no status table.

HOW TO EDIT THESE PROMPTS
Every prompt states its goal, what to read, its constraints, and when it is done. None says how
to do the work; the session decides that. When a prompt needs a fact, add it to Shared context
and point to it rather than restating it in the prompt.
-->

# Evaluation harness: project prompts

Repository: `eval-coding-agent-harness`. This is a working name; to rename, replace it throughout
this file before running P0.

## Prompts in order

Status is tracked in beads: run `br ready`. This list only maps the file.

| ID       | Prompt                                    | Runs on   |
| -------- | ----------------------------------------- | --------- |
| P0       | Bootstrap the repository and devcontainer | host      |
| P0B      | Adopt beads for all tracking              | container |
| P1       | Toolchain and quality gate                | container |
| P2       | Architecture docs                         | container |
| P3       | Global spec and spec index                | container |
| P4       | Engine boundary spike and ADRs            | container |
| SPEC-01  | Spec: run record                          | container |
| BUILD-01 | Build: run record                         | container |
| SPEC-02  | Spec: workspace and conditions            | container |
| BUILD-02 | Build: workspace and conditions           | container |
| SPEC-03  | Spec: integrity                           | container |
| BUILD-03 | Build: integrity                          | container |
| SPEC-04  | Spec: host adapters, Claude and Codex     | container |
| BUILD-04 | Build: host adapters, Claude and Codex    | container |
| SPEC-05  | Spec: instruments                         | container |
| BUILD-05 | Build: instruments                        | container |
| SPEC-06  | Spec: experiment and pre-registration     | container |
| BUILD-06 | Build: experiment and pre-registration    | container |
| SPEC-07  | Spec: runner                              | container |
| BUILD-07 | Build: runner                             | container |
| SPEC-08  | Spec: analysis                            | container |
| BUILD-08 | Build: analysis                           | container |
| SPEC-09  | Spec: report and re-score                 | container |
| BUILD-09 | Build: report and re-score                | container |
| SPEC-10  | Spec: end-to-end                          | container |
| BUILD-10 | Build: end-to-end                         | container |
| SPEC-11  | Spec: OpenCode host                       | container |
| BUILD-11 | Build: OpenCode host                      | container |
| SPEC-12  | Spec: Antigravity CLI host                | container |
| BUILD-12 | Build: Antigravity CLI host               | container |
| SPEC-13  | Spec: Muse Code host                      | container |
| BUILD-13 | Build: Muse Code host                     | container |

---

## Shared context

Every prompt below assumes this section. Read it before running any prompt.

### What the harness is

A skill author edits a `SKILL.md` and cannot tell whether the edit changed what the coding agent
writes. The agent writes a different document every run even when nothing changes, so a
with-and-without comparison always shows a difference. The harness runs the agent many times under
conditions that differ only in the skill body. Then it reports how much the output moved, with
its uncertainty, and with the other explanations ruled out.

Those other explanations ("rivals") are what the harness exists to rule out:

- prompt wording;
- the skill's frontmatter;
- instruction files the host loads on its own;
- files left by an earlier run;
- the agent reading the reference answer;
- a check that recorded "could not read" as "not found";
- uneven exclusion between conditions;
- thresholds chosen after the results;
- runs made under different hosts or versions.

Each control rules out one rival and has a test that seeds the breakage it catches.

promptfoo is the engine. It runs and repeats the agent through a provider for each host, stores
every output with its metadata, applies assertions, and shows results. The harness adds what
promptfoo lacks:

- conditions held equal;
- isolated single-use workspaces;
- a record for every run, with a declared outcome class;
- scorers that cannot see the condition;
- pre-registration;
- exact intervals;
- differences between conditions;
- a gate that refuses to compare mismatched runs.

Keep the control logic independent of promptfoo, so that a second engine could be added later.

The harness is a library and a command-line tool. It ships no skill. A sample skill exists only as
a test fixture.

### Hosts

A host is the coding agent that loads the skill and does the work. Each host is reached through
one adapter. Adding a host means writing that adapter and its fixtures; no control code changes.

| Order | Host            | Vendor                             | CLI        | promptfoo provider                                   | Unverified until P4                                         |
| ----- | --------------- | ---------------------------------- | ---------- | ---------------------------------------------------- | ----------------------------------------------------------- |
| 1     | Claude Code     | Anthropic                          | `claude`   | stock: `anthropic:claude-agent-sdk`                  | —                                                           |
| 2     | Codex           | OpenAI                             | `codex`    | stock: `openai:codex-sdk`, `openai:codex-app-server` | Reliable single-skill exposure (ADR-0001 amendment 4)       |
| 3     | OpenCode        | open source; runs any lab's models | `opencode` | stock: `opencode:sdk`                                | Skill exposure and ambient-config exclusion                 |
| 4     | Antigravity CLI | Google                             | `agy`      | none; ours, shelling out to the CLI                  | Headless run, machine-readable output, isolation levers     |
| 5     | Muse Code       | Meta                               | `muse`     | none; ours, shelling out to the CLI                  | Whether it reads `SKILL.md` at all; headless run; isolation |

- Claude Code and Codex come first: their providers ship with promptfoo and the reference repo
  already ran Claude Code.
- OpenCode is next. It holds the host fixed while the model varies, which separates a model effect
  from a host effect.
- Antigravity CLI is Google's host. Gemini CLI was retired for individual accounts on 2026-06-18
  and replaced by it. It reads skills from `.agents/skills/`, as Codex does.
- Muse Code entered beta on 2026-08-05. Build it only if P4 shows it can run a `SKILL.md`
  headlessly; otherwise its rows are blocked with the reason.
- GitHub Copilot CLI and Cursor CLI are out of scope by decision.

### The reference repository

`/workspaces/coding-agent-skills-tdd` is mounted read-only. It holds the first version of this
harness, built for one skill and one experiment. Build from it; do not copy it. Read, as a prompt
needs them:

| Path                                                                              | What it gives you                                                     |
| --------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `EVAL_HARNESS_DESIGN.md`                                                          | User stories, acceptance criteria and status; the main source         |
| `EVAL_HARNESS_CONTROLS.md`                                                        | The 18 built controls and the planned ones, in plain English          |
| `EVAL_HARNESS_DESIGN_ANALYSIS.md`                                                 | Which requirements earn their place, and why                          |
| `EVAL_HARNESS_REVIEW.md`                                                          | Criteria mapped to code, and the gaps                                 |
| `EVAL_HARNESS_HOWTO.md`                                                           | How the old harness is run and tested                                 |
| `RESEARCH_PRIOR_ART_ANALYSIS.md`, `docs/prior-art-research-*.md`                  | What existing tools already do; vocabulary to reuse                   |
| `docs/decisions/0001-evaluation-engine.md`                                        | Why promptfoo; amendments 3 and 4 list what each provider supplies    |
| `eval/`, `spec/eval/`                                                             | The old implementation and its tests                                  |
| `.devcontainer/`, `.vscode/`, `Makefile`, `package.json`, `docs/writing-style.md` | Environment and conventions to learn from                             |
| `eval/runs/`                                                                      | 84 recorded runs; useful as test fixtures, never as a comparison side |

These old-harness defects must not carry over (details in `EVAL_HARNESS_DESIGN.md`):

- The engine and SDK versions are hardcoded.
- The model, case and artifact name are constants.
- A refused preflight is recorded under the wrong outcome class.
- The preflight checks only the workspace root.
- Nothing computes the difference between two conditions.
- Nothing flags uneven exclusion between conditions (attrition).
- Nothing gates publication on the positive control firing.
- The pre-registration is not linked to the run records.
- Records are not re-scored when the scoring code changes.
- The run record is shaped to Claude Code's output.

### Tracking

beads_rust (`br`) is the only tracker, from P0B onward. Only the Claude Code session that runs
these prompts uses it; the hosts under test never see it. The project skill
`.claude/skills/beads-sdd/SKILL.md` (written by P0B) holds the commands; these are the rules.

- **Prompts are beads.** Every prompt has one bead whose title starts with its prompt ID. Its
  dependencies follow the Subsystems table: BUILD-NN depends on SPEC-NN, and SPEC-NN depends on
  the BUILD beads of the subsystems it depends on.
- **Next.** Run `br ready --label prompt` and take the ready prompt listed first in "Prompts in
  order". Run one prompt at a time unless the user says otherwise.
- **State.**
    - Set a bead to in progress when its prompt starts.
    - Close it with the commit hash when the prompt is done.
    - If the prompt cannot finish, set the bead to blocked with the reason, and stop.
- **Specs and tasks.**
    - A spec holds each task's text and Verify command under a stable ID `NN.k`, with no checkbox
      and no status.
    - When the user approves a spec, close its SPEC bead and create one bead per task. The bead's
      title starts with `NN.k`, it carries the label `spec-NN`, its parent is the BUILD-NN bead, and
      its dependencies mirror the tasks'.
    - A task bead points to its spec task; it never copies the task text.
    - The spec names only its BUILD bead, in its `Tracking:` line.
- **Review.** A finished spec's bead carries the label `awaiting-review` and stays open until the
  user approves.
- **Discovered work.** Anything found outside the current prompt becomes a bead labelled `spec-NN`,
  or `harness` if it belongs to no spec. It never duplicates a spec task. When it is taken into a
  spec, it becomes a task there, and its bead is closed with a reason naming the task.
- **Committed.** `.beads/issues.jsonl` is committed with the work it describes. The database file
  is not committed.
- **Checked.** The gate fails if:
    - an approved spec has a task with no bead;
    - a `spec-NN` bead names a task that doesn't exist;
    - a closed BUILD bead has open task beads.

### Rules for every prompt

- **Language.** Use TypeScript by default. Use a POSIX `sh` script when it is shorter and plainer
  than the TypeScript would be: file and process work, snapshots, small glue. Shell scripts start
  with `#!/bin/sh` and contain no bashisms.
- **Test first.** Write the test, watch it fail, then implement. Every control gets a test that
  seeds the breakage it detects. Unit tests never call a model or need a login.
- **Spec first.** No harness code is written without an approved spec under `docs/specs/`.
- **Done.** A prompt is done when the repo's single quality gate (set up by P1) passes, the work
  is committed, and its bead is closed as Tracking describes.
- **Scope.** Do what the prompt asks. Record anything else you notice as a bead (see Tracking).
  Open Questions in a spec are for questions about that spec.
- **Writing.** Docs follow `docs/arch/writing-style.md` once P2 creates it: plain, specific,
  checkable, with each fact stated once.

### Spec template

Every spec is `docs/specs/NN-name/spec.md` with these sections, in this order:

```markdown
# NN — {Name}

Tracking: {BUILD-NN bead ID}

## Overview

{1-2 sentence description of what this spec delivers and why.}

## Problem Statement

{What user problem does this solve? Why does this need to exist? Focus on user pain, not the
solution.}

## Solution Statement

{What exists afterwards and who benefits. The mechanism in a few sentences.}

## User Stories

- As a {role}, I can {action} so that {benefit}.

## Acceptance Criteria

- **AC-1** {Specific, testable criterion}

## Out of Scope

{Explicit exclusions to prevent scope creep. If nothing is excluded, boundaries are too soft.}

## Open Questions

{Unresolved questions. Write "None" if all questions resolved.}

- [ ] {Question that needs answering}
- [x] ~{Resolved question}~ → {Decision made}

## Design Decisions

_Document the "Why" behind the "How." Each decision records what was chosen, the rationale, and
what was rejected and why._

### 1. {Decision Name}

- **Chosen:** {What was selected}
- **Why:** {1-2 sentences of rationale}
- **Rejected:** {Alternative} — {Why not, 1 sentence}

## Traceability

_Every acceptance criterion from the spec maps to at least one task. Gaps here are planning
failures._

| Spec Acceptance Criterion | Addressed In Task(s) |
| :------------------------ | :------------------- |
| AC-1                      | {NN.k task IDs}      |

<!-- If a spec AC has no task, it is either Out of Scope (document it there) or a planning gap (add a task). -->
<!-- Use [NEEDS CLARIFICATION] marker for any AC that is ambiguous or technically underspecified. -->

## Task Breakdown

_Ordered by dependency. Each task is atomic (one thing changed, one thing verifiable) and
independently confirmable. Status is not kept here; it lives in the task's bead._

- **NN.1** {Task description — what file, what change, what interface it satisfies}
  **Depends on:** {NN.k IDs, or none}
  **Verify:** `{shell command that proves this task is complete}`
```

---

## Phase 0 — on the host

### P0 — Bootstrap the repository and devcontainer

**Runs on:** the host, in the new empty folder `../eval-coding-agent-harness`, a sibling of
`coding-agent-skills-tdd`.

**Goal:** a git repository holding the devcontainer configuration and project files that every
later prompt needs. P0 writes files; the container is built afterwards, by the user, and checked by
P1.

**Read first:** the reference repo's `.devcontainer/devcontainer.json`, `.devcontainer/postCreate.sh`,
`.vscode/`, `package.json`, `.editorconfig`, `.prettierrc` and `CLAUDE.md`. Their comments record
problems that were already solved, such as volume ownership, nvm group permissions, the statusline
bind mount and auth persistence. Solve the same problems; don't copy the files.

**The container must provide:**

- Node at the version promptfoo requires.
- The CLI of every host in Shared context → Hosts, each with its login persisted in a volume
  scoped to this repository. If a host has no Linux install, record that in the README and
  continue.
- `gh`, a formatter, a shell linter and formatter, and whatever shell test runner P1 will need.
- The reference repository bind-mounted read-only at `/workspaces/coding-agent-skills-tdd`, the
  same path it has in its own container.

**Also create:**

- `.vscode/` with a purple colour theme, replacing the reference repo's green.
- `package.json`.
- `.gitignore`, `.editorconfig` and formatter config.
- A stub `README.md`.
- `CLAUDE.md` holding the project rules from Shared context, with `AGENTS.md` pointing to it,
  because the other hosts read `AGENTS.md`.
- A copy of this file as `PROMPTS.md`.

**Constraints:**

- Install nothing on the host. Run no package manager, installer or container build there. Every
  tool is installed inside the container by `postCreate.sh` or a devcontainer feature.
- The harness will run agents in workspaces outside this repository. Don't let this repository's
  own `CLAUDE.md` or `AGENTS.md` sit anywhere a run's workspace could inherit them, for any host,
  and note that rule in `CLAUDE.md`.

**Done when:**

- Every file above exists and the first commit is made.
- The session tells the user to open the folder in VS Code, choose **Reopen in Container**, log
  in to each host, and then run P0B.

### P0B — Adopt beads for all tracking

**Runs on:** the container, after P0.

**Goal:** from here on, beads_rust is the only tracker, as Shared context → Tracking describes,
and every later prompt can be found with `br ready`.

**Read first:** Shared context → Tracking; the beads_rust README and its `AGENTS.md`
(github.com/Dicklesworthstone/beads_rust).

**Deliver:**

- `br` installed at a pinned version by `postCreate.sh`, and installed in the running container
  as well so work continues without a rebuild.
- Beads initialised in the repo.
- One bead per prompt in "Prompts in order", with the dependencies Tracking describes. P0 and P0B
  are recorded as closed beads with their commits.
- `PROMPTS.md` replaced by
  `/workspaces/coding-agent-skills-tdd/EVAL_HARNESS_PROJECT_PROMPTS.md`, the version holding this
  prompt.
- `CLAUDE.md` gains the Tracking rules in a few lines; `AGENTS.md` keeps pointing to it.
- The project skill `.claude/skills/beads-sdd/SKILL.md`: how to apply each Tracking rule with
  `br`. Decide whether to build on upstream's `beads@beads-rust` Claude Code plugin, and record
  why. The skill must not be reachable from an evaluation workspace.

**Done when:**

- `br ready` lists P1 as the only ready prompt.
- `.beads/issues.jsonl` and every file above are committed.
- The P0B bead is closed.

---

## Phase 1 — foundation, in the container

### P1 — Toolchain and quality gate

**Goal:** one command that every later prompt treats as "done". It lints, checks formatting and
runs every model-free test for both TypeScript and shell. It needs no credentials and finishes in
seconds.

**Read first:** the reference `Makefile` and `EVAL_HARNESS_HOWTO.md` (model-free commands).

**Check the container first.** If any check fails, set the P1 bead to blocked with the failure
and fix the devcontainer before anything else:

- `node --version`, `br --version` and each host's version command run.
- `/workspaces/coding-agent-skills-tdd` is readable but not writable.
- Each host's login, and `br`, survive a container rebuild.

**Include:**

- Prove each installed host's login works by running one trivial prompt on it.
- Record the installed versions of every host, promptfoo and Node in the README.
- Prove the test loop: commit one test that failed before its code existed and passes now.
- Include in the gate the check of specs against beads described in Tracking. It reads the
  committed JSONL, so CI needs no `br`.
- Add a CI workflow that runs the gate.

**Done when:** the gate passes locally and in CI, and the README says how to run it.

### P2 — Architecture docs

**Goal:** `docs/arch/` tells a new contributor how the project is laid out, how to set it up, how
it is tested and how it will be used.

**Write:**

| File                | Contents                                                                                                                          |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `toc.md`            | Table of contents for `docs/`                                                                                                     |
| `project-layout.md` | Folders, naming, where TypeScript goes and where shell goes, and how to choose between them                                       |
| `testing.md`        | How harness code is tested: TDD, seeded-breakage tests, fixtures, the gate. Not evals                                             |
| `setup.md`          | Local setup: devcontainer, the login for each host, first gate run                                                                |
| `usage.md`          | How to run an experiment. A skeleton until the subsystems land; each BUILD prompt fills its part                                  |
| `glossary.md`       | Condition, placebo, positive control, instrument, run record, outcome class, pre-registration, contrast, attrition, host, adapter |
| `controls.md`       | Each rival explanation and the control that rules it out; built from the reference `EVAL_HARNESS_CONTROLS.md`                     |
| `spec-process.md`   | How specs are written (the template above), reviewed, linked to beads and tracked to done; points to the beads-sdd skill          |
| `writing-style.md`  | Voice rules for every doc, adapted from the reference `docs/writing-style.md`                                                     |
| `decisions/`        | Architecture decision records (ADRs), numbered; empty until P4                                                                    |

**Also:** the README links to `setup.md` and `usage.md`.

**Done when:** every file exists, nothing in it contradicts Shared context, and the gate passes.

### P3 — Global spec and spec index

**Goal:** the requirements for the whole harness, and the order in which subsystem specs will be
written.

**Read first:**

- `docs/arch/`;
- the reference `EVAL_HARNESS_DESIGN.md`, `EVAL_HARNESS_DESIGN_ANALYSIS.md` and
  `EVAL_HARNESS_CONTROLS.md`;
- ADR-0001 amendment 4.

**Write:**

- `docs/specs/00-harness/spec.md`, in the template. Its user stories cover every control, built or
  planned, in the reference docs, plus every host in Shared context → Hosts and reuse across
  skills, cases, models and host versions. One criterion: adding a host means one adapter and its
  fixtures, and no change to control code. Copilot CLI and Cursor CLI go in Out of Scope. Its tasks
  are the subsystem specs themselves.
- `docs/specs/README.md`. List the subsystem specs in build order, with each one's dependencies.
  No status column: status is in beads. Start from the Subsystems table, and change the order if the
  global spec argues for something else. If it changes, update the prompt beads' dependencies to
  match.

**Done when:**

- Every acceptance criterion in the global spec maps to a subsystem.
- Every planned control from the reference docs is either assigned to a subsystem or listed as Out
  of Scope with a reason.
- The spec is committed and the P3 bead carries `awaiting-review`.

### P4 — Engine boundary spike and ADRs

**Goal:** settle by running, not by reading, what promptfoo's stock providers give each host and
where the harness takes over.

**Read first:**

- `docs/specs/00-harness/spec.md`;
- the reference ADR-0001, amendments 3 and 4;
- the reference `RESEARCH_PRIOR_ART_ANALYSIS.md`.

**Do:** run one real trial of a trivial fixture skill on every host in Shared context → Hosts:
through the stock provider for Claude Code, Codex and OpenCode, and directly through the CLI for
Antigravity and Muse Code. For each, establish:

- how a single skill is exposed;
- which ambient configuration can be excluded;
- whether the working directory can be set per trial;
- which metadata comes back: served models, usage, skill activation, permission denials, stop
  reasons;
- for hosts without a stock provider: whether it runs headless and non-interactively, and whether
  its output is machine-readable.

A host that fails these checks is recorded as such in the host-adapter ADR, and its SPEC and BUILD
beads are set to blocked with the reason. Do not work around a missing capability.

**Write ADRs in `docs/arch/decisions/` for:**

- the engine's role: promptfoo for v1, with control logic engine-independent;
- the TypeScript/shell split;
- the boundary of the host adapter, including the pattern for a host with no stock provider.

Record as open questions in the global spec:

- a second engine (Inspect AI is the candidate that runs agents in sandboxes);
- export to tracing platforms such as Langfuse or LangSmith.

**Done when:**

- Each ADR cites what the spike observed.
- The global spec's open questions are updated.
- Spike output that tests can reuse is saved as fixtures.

---

## Phase 2 — subsystems, in the container

Each subsystem takes two prompts: SPEC-NN, then BUILD-NN. Both are written once, below, and take
the subsystem's row from the table that follows. Its Depends on column sets the prompt beads'
dependencies.

### SPEC-NN — Write a subsystem spec

**Goal:** `docs/specs/NN-name/spec.md`, in the template, ready for the user to review.

**Read first:**

- the global spec;
- the specs this one depends on;
- the ADRs;
- the reference sources named in this subsystem's row below.

**Constraints:**

- Each acceptance criterion is testable without a model.
- Each control has a criterion for the breakage it must catch.
- Every acceptance criterion maps to a task, and every task has an `NN.k` ID, its dependencies and
  a Verify command.
- Fold in the open beads labelled `spec-NN`, as Tracking describes.
- Resolve the open questions you can. Leave the rest open; don't guess.

**Done when:** the spec is committed, the spec index is updated, and the SPEC bead carries
`awaiting-review`. On the user's approval, close the SPEC bead and create the task beads, as
Tracking describes.

### BUILD-NN — Build a subsystem

**Goal:** the subsystem works as the approved spec says.

**Constraints:**

- Work the ready task beads labelled `spec-NN`, test first.
- Close each task bead with its commit once its Verify command passes.
- When a task turns out to be wrong, change the spec first and say so in the commit.
- Fill this subsystem's part of `docs/arch/usage.md`.

**Done when:**

- Every task bead is closed.
- The gate passes.
- The BUILD bead is closed.

### Subsystems

| NN  | Name                           | Goal                                                                                                                                                                                                                                                                           | Reference sources                                                                                          | Depends on |
| --- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------- | ---------- |
| 01  | run-record                     | One record per attempted run, independent of the host, with a single outcome class from a fixed precedence and a declared denominator treatment for each class. Undeclared classes fail loudly                                                                                 | `eval/collect.mjs`, `eval/aggregate.mjs`; design stories 5 and 8; review G6                                | —          |
| 02  | workspace-and-conditions       | A fresh workspace per run, outside the repo. Every condition built from one `SKILL.md` (none, real, seeded, placebo), differing only in the body. Exposure works for every host's skill location. Preflight covers every ancestor directory and the user config, with a canary | `eval/lib/workspace.sh`, `eval/prepare-run`, `eval/fixtures/`; design stories 1, 3 and 4                   | 01         |
| 03  | integrity                      | Input and repository unchanged, reads confined to the workspace (a denied read is not an escape), and every check fails closed                                                                                                                                                 | `eval/lib/evidence.sh`, `verifyReadScope`; design story 4                                                  | 01, 02     |
| 04  | host-adapters                  | The host-adapter interface, then Claude Code and Codex trials through their stock promptfoo providers. Capture served models, usage summed over every model, skill activation, denials and stop reasons. Every version is read from the running system                         | `eval/run-condition.mjs`, `eval/provider.mjs`; ADR-0001 amendments 3 and 4; design story 12; P4's ADRs     | 01, 02     |
| 05  | instruments                    | A scorer interface that sees only the artifact and its parameters and returns fired, silent or error. A promptfoo assertion wrapper that never sees the condition. The first deterministic instruments, and a plug-in point for a model judge                                  | `eval/checks.mjs`; design stories 2 and 10                                                                 | 01         |
| 06  | experiment-and-preregistration | An experiment as data: skill, case, model, host and conditions, each in its own directory. A write-once pre-registration whose hash is stamped on every record, carrying a positive-control minimum and an attrition tolerance. Amendments written by code                     | `eval/pre-register.mjs`; design stories 6 and 9                                                            | 01         |
| 07  | runner                         | Generate the promptfoo test matrix from an experiment, one test per trial, each with its own working directory. Record attempts and admitted runs, apply one replacement rule to all conditions, and run everything with one command                                           | `eval/promptfooconfig.yaml`; design stories 5 and 12; design footnotes 7 and 8                             | 02–06      |
| 08  | analysis                       | k of n with exact bounds; differences between conditions with intervals; the comparability gate; the attrition flag; the positive-control gate; one of four verdicts (effect attributed, no effect detected, inconclusive, instrument failed)                                  | `eval/aggregate.mjs`, `eval/bounds.mjs`; design stories 2, 3, 5 and 7; `RESEARCH_PRIOR_ART_ANALYSIS.md` D1 | 01, 06     |
| 09  | report-and-rescore             | A report produced from the records alone, which a reader can recompute. Re-score preserved artifacts whenever the scoring code changes                                                                                                                                         | `scripts/figures/01.mjs`, `scripts/check-article.mjs`; design story 8                                      | 05, 08     |
| 10  | end-to-end                     | Run an article-1-style experiment on a sample fixture skill under Claude Code and Codex, from experiment definition to verdict. `usage.md` complete                                                                                                                            | `EVAL_HARNESS_HOWTO.md`; the old `eval/runs/` as a comparison of shape, not of results                     | 01–09      |
| 11  | host-opencode                  | OpenCode through its stock provider. Run the end-to-end experiment on it with two models from different labs. No control code changes                                                                                                                                          | ADR-0001 amendment 4; P4's ADRs and fixtures                                                               | 10         |
| 12  | host-antigravity               | Antigravity CLI through our own promptfoo provider. Run the end-to-end experiment on it. No control code changes                                                                                                                                                               | P4's ADRs and fixtures; the reference `eval/provider.mjs` as the pattern of a provider that shells out     | 10         |
| 13  | host-muse-code                 | Muse Code through our own promptfoo provider, if P4 showed it can run a `SKILL.md` headlessly. Run the end-to-end experiment on it. No control code changes                                                                                                                    | P4's ADRs and fixtures; subsystem 12's provider                                                            | 12         |
