# Spec process and daily routine

How a spec is written, reviewed and tracked to done, and what a working session looks like. The
rules are in `PROMPTS.md` → Shared context → Tracking; the `br` commands that apply them are in
`.claude/skills/beads-sdd/SKILL.md`.

## Writing a spec

Each subsystem in `PROMPTS.md` → Subsystems gets one spec, `docs/specs/NN-name/spec.md`, written by
its SPEC-NN prompt. The spec follows the template in `PROMPTS.md` → Spec template, with every
section in its order. The template is not copied here.

What a reviewer checks:

- Every acceptance criterion can be tested without a model.
- Every [control](controls.md) the spec owns has a criterion for the breakage it must catch.
- Every acceptance criterion maps to at least one task in Traceability. A criterion with no task is
  either moved to Out of Scope or gets a task.
- Every task has an ID `NN.k`, its dependencies and a Verify command. It has no checkbox and no
  status.
- Open beads labelled `spec-NN` are folded in, as `PROMPTS.md` → Tracking → Discovered work
  describes.
- Open Questions holds only what the author could not resolve, and nothing is guessed.
- `Tracking:` names the BUILD-NN bead, and no other bead.

## From review to done

The finished spec is committed, `docs/specs/README.md` lists it, and the SPEC-NN bead gets the
label `awaiting-review`. On the maintainer's "approved", the SPEC-NN bead is closed and one bead is
created per task; BUILD-NN then works those beads test first and is closed when they all are.
`PROMPTS.md` → Tracking → Specs and tasks gives the rules, and the beads-sdd skill gives the
commands. The gate's `check-beads` target checks that specs and beads still agree
([`testing.md`](testing.md)).

## A working session

1. **Start.** Open a Claude Code session in the repository and say "next". Claude runs
   `br ready --label prompt`, takes the first ready prompt in `PROMPTS.md` order and sets its bead
   to in progress. One prompt at a time, unless the maintainer says otherwise. A fresh session is fine: the beads carry the state.
2. **Work.** What each side does depends on the prompt:

    | Prompt                 | Claude does                                                                           | The maintainer does                                                     |
    | ---------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
    | `P1`–`P4` (foundation) | Builds it, runs the gate, commits, closes the bead; P3 instead ends `awaiting-review` | Skims the commit and says if anything is off                            |
    | `SPEC-NN`              | Writes `docs/specs/NN-name/spec.md` and labels the bead `awaiting-review`             | Reviews the spec, answers its Open Questions, then says "approved"      |
    | `BUILD-NN`             | Works the spec's task beads test first, closing each with its commit                  | Steps in only when a task turns out to be wrong; the spec changes first |

    Spec review is the maintainer's main control point. Once a spec is approved, its BUILD runs
    from the task beads.

3. **Stop.** Before ending a session, the working tree is clean: the work is committed, and the
   bead is closed with its commit hash or set to blocked with the reason. Ask "we good" to have
   Claude check.

Anything found outside the current prompt becomes a bead labelled `spec-NN`, or `harness` when it
belongs to no spec. It is not fixed in the current work.

## Commands

```sh
br ready                          # what can be worked now
br list --status in_progress      # what is under way
br show <id>                      # one bead in full
br list --label awaiting-review   # specs waiting for review
```
