# Glossary

The terms the harness uses, each defined once. Other documents link here instead of redefining
them.

**Skill.** A `SKILL.md` file: YAML frontmatter (`name`, `description`) and a Markdown body of
instructions that a host loads into the agent. The harness tests skills; it ships none.

**Host.** The coding agent that loads the skill and does the work, such as Claude Code or Codex.
The hosts the project targets are listed in `PROMPTS.md` → Shared context → Hosts.

**Adapter.** The one piece of code that connects the harness to one host. It exposes the skill,
starts a run and turns the host's output into a run record. Adding a host means adding an adapter
and its fixtures; no control code changes.

**Engine.** The tool that runs and repeats the agent, stores outputs and applies assertions.
promptfoo is the engine for version 1. The harness keeps its control logic outside the engine.

**Condition.** One configuration of a run. The conditions of an experiment differ only in the
skill body. The usual four are: no skill, the real skill, the real skill with a seeded defect, and
a placebo.

**Placebo.** A condition whose skill has the same frontmatter as the real skill and a body that
prescribes nothing. Comparing it with no skill shows what invoking any skill does. Comparing the
real skill with it shows what this body does.

**Positive control.** The condition where the effect is known to be present, usually the seeded
defect. An instrument that stays silent there is broken, so its silence elsewhere means nothing.

**Instrument.** A function that scores one artifact, the file the agent wrote, and returns exactly
one of `fired`, `silent` or `error`. It sees the artifact and its own parameters, never the
condition. `error` says why: the artifact was missing, unreadable or empty.

**Run.** One attempt by the agent at one case under one condition, in its own single-use
workspace. A run that is attempted but excluded is still a run.

**Run record.** The record written for every run, whatever happened to it: what was run, under
which versions, what came back, and its outcome class.

**Outcome class.** The single class a run record carries, assigned by one fixed precedence that
is the same for every condition: for example admitted, contaminated or no output file. Each class
declares in advance whether it counts in a rate's denominator. A class with no declaration stops
the analysis with an error.

**Pre-registration.** The thresholds and accounting rules of an experiment, written once before
its runs. Its hash is stamped on every run record, so a reader can tell which rules governed which
runs. Changes are amendments written by code, never hand edits.

**Contrast.** A difference between two conditions' rates, reported with its interval. For example,
real skill minus placebo.

**Attrition.** The runs a condition loses to exclusion. When two conditions in a contrast lose
very different fractions, the runs left are no longer comparable samples, and the contrast is
flagged.

**Rival.** An explanation other than the skill body for a difference between conditions. Each
control rules out one; [`controls.md`](controls.md) lists them.

**Verdict.** The result of an experiment: effect attributed, no effect detected, inconclusive, or
instrument failed.
