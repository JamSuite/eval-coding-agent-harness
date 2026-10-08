# Spec process and daily routine

How work moves from `PROMPTS.md` to done. The rules are in `PROMPTS.md` → Shared context →
Tracking; the `br` commands that apply them are in `.claude/skills/beads-sdd/SKILL.md`. This page
says what a working session looks like and what the maintainer does in it.

## A working session

1. **Start.** Open a Claude Code session in the repository and say "next". Claude runs
   `br ready --label prompt`, takes the first ready prompt in `PROMPTS.md` order and sets its bead
   to in progress. One prompt per session. A fresh session is fine: the beads carry the state.
2. **Work.** What each side does depends on the prompt:

    | Prompt                 | Claude does                                                               | The maintainer does                                                     |
    | ---------------------- | ------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
    | `P1`–`P4` (foundation) | Builds it, runs the gate, commits, closes the bead                        | Skims the commit and says if anything is off                            |
    | `SPEC-NN`              | Writes `docs/specs/NN-name/spec.md` and labels the bead `awaiting-review` | Reviews the spec, answers its Open Questions, then says "approved"      |
    | `BUILD-NN`             | Works the spec's task beads test first, closing each with its commit      | Steps in only when a task turns out to be wrong; the spec changes first |

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
