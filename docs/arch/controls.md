# Controls

Every [rival](glossary.md) explanation the harness rules out, and the control that rules it out.
The agent writes a different document on every run, so two [conditions](glossary.md) always
differ. A control removes one reason, other than the skill body, for why they differ. Each control
has a model-free test that seeds the breakage it catches and checks that it catches it
([`testing.md`](testing.md)).

The controls come from the reference repository's `EVAL_HARNESS_CONTROLS.md`, which describes 18
built for one skill and one experiment, and the ones planned there. The "Ref." column gives the
number of the built control there, or "planned". The "Spec" column names the subsystem spec that
owns the control here; the subsystems are listed in `PROMPTS.md` → Subsystems. Whether a control
is built yet is tracked in beads, not here. The owners follow the Subsystems table; where P3's
global spec assigns a control differently, the global spec wins and this table is updated.

## The rivals in Shared context

These are the rivals `PROMPTS.md` → Shared context names.

| Rival                                                 | Control                                                                                                                                                                                                                              | Ref.        | Spec   |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- | ------ |
| Prompt wording                                        | Every condition of an experiment sends the same prompt, checked by a test rather than by inspection.                                                                                                                                 | planned     | 07     |
| The skill's frontmatter                               | Every condition's skill is built from one source `SKILL.md`. Each gets a frontmatter of only `name` and `description`, byte-identical across conditions, so the conditions differ only after the closing `---`.                      | 3           | 02     |
| Instruction files the host loads on its own           | Before a run, a preflight refuses it if an instruction file sits in the workspace, in any directory above it, or in the user's host configuration. A unique canary string planted at each level shows whether any reached the model. | 2, planned  | 02     |
|                                                       | Only the skill under test is exposed, in the location the host reads skills from. The no-skill condition exposes none, and the repository is never exposed.                                                                          | 4           | 02     |
| Files left by an earlier run                          | Every run gets a new workspace outside the repository, with the case in its input folder, an empty output folder and a run identifier never used before.                                                                             | 1           | 02     |
|                                                       | The repository is unchanged by a run: a content snapshot before and after, and a run that changed it is rejected.                                                                                                                    | 7           | 03     |
| The agent reading the reference answer                | Reads are confined to the workspace, then verified from the transcript after the run. A read the permission rule refused is not an escape. A run with an escaped read, or no transcript to check, is excluded.                       | 5           | 03     |
| A check that recorded "could not read" as "not found" | An [instrument](glossary.md) returns `fired`, `silent` or `error`, never `silent` for a file it could not read.                                                                                                                      | 9           | 05     |
|                                                       | Every integrity check fails closed: a check that cannot open a file reports a violation, never a match.                                                                                                                              | 8           | 03     |
| Uneven exclusion between conditions                   | Every attempted run leaves a [run record](glossary.md), even when the harness itself crashed.                                                                                                                                        | 11          | 01     |
|                                                       | Each run gets one [outcome class](glossary.md) from one fixed precedence, and each class declares its denominator treatment in advance. An undeclared class stops the analysis.                                                      | 12, 13      | 01     |
|                                                       | Attempts and admitted runs are both recorded per condition, and one replacement rule applies to every condition.                                                                                                                     | planned     | 07     |
|                                                       | A contrast is flagged when its two conditions lost very different fractions of runs ([attrition](glossary.md)), against a tolerance set in the pre-registration.                                                                     | planned     | 08     |
| Thresholds chosen after the results                   | The [pre-registration](glossary.md) is written once, before the runs; a second write is refused. It carries the positive-control minimum and the attrition tolerance.                                                                | 17, planned | 06     |
|                                                       | Every run record carries the hash of the pre-registration in force, and a check shows from the records that it predates every run.                                                                                                   | 18, planned | 06     |
|                                                       | Amendments are written by tested code, never by hand.                                                                                                                                                                                | planned     | 06     |
| Runs made under different hosts or versions           | A contrast is refused when its conditions differ in host, host version, engine version, SDK version, model, tool list or permission rule. Every version is read from the running system, never written in as a constant.             | 16, planned | 04, 08 |
|                                                       | Model, case, host and artifact are settings of an experiment, and each experiment has its own directory and pre-registration, so an old run set is never reused under a new model or host.                                           | planned     | 06     |

## Other errors the controls rule out

The reference controls also guard against these. The first five are rivals; the last four are
errors in accounting and reporting. They are named here so that no control loses its reason.

| Error                                                | Control                                                                                                                                                                       | Ref.        | Spec |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | ---- |
| Chance: the output varies from run to run            | Every rate is reported as k of n with an exact binomial bound, and every contrast with an interval. The caller says whether a bound is one- or two-sided.                     | 15          | 08   |
| Invoking any skill, rather than this skill's body    | A [placebo](glossary.md) condition, and two contrasts reported separately: placebo minus no skill, and real skill minus placebo.                                              | planned     | 08   |
| The agent edited its own input                       | A pristine copy of the case is kept outside the workspace and compared byte for byte after the run.                                                                           | 6           | 03   |
| The scorer knows the condition                       | Instruments receive only the artifact and their own parameters, and a test checks that the condition cannot reach them. A model judge or a human score plugs in the same way. | 10, planned | 05   |
| A broken instrument reads as "no effect"             | When the [positive control](glossary.md) fires below its pre-registered minimum, the verdict is "instrument failed" and nothing is attributed.                                | planned     | 08   |
| Records scored by older scoring code                 | Each record carries a digest of the scoring code, and records are re-scored whenever it changes.                                                                              | planned     | 09   |
| A mistyped or stale figure in a report               | Every reported number is produced from the records by harness code, and a reader can recompute it.                                                                            | planned     | 09   |
| Cost read from one model when several served the run | Usage is summed over every model that served the run.                                                                                                                         | 14          | 04   |
| A refused preflight counted as a harness bug         | A run the preflight refused is recorded as refused by preflight, its own outcome class.                                                                                       | planned     | 01   |

Two planned changes alter how a built control works rather than add one. The exact bounds are to
come from a published statistics package instead of hand-written code. And with promptfoo's stock
providers, the read-scope check takes its data from the provider's output instead of from the
transcript, where a provider supplies it.
