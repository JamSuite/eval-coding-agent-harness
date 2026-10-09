# Usage

[⬑ Back to arch TOC](./index.md)

How to run an experiment: define it, pre-register it, run it, and read the verdict. This page is a
skeleton until the subsystems are built. Each BUILD prompt fills in its own section, and BUILD-10
completes the page with a worked example from definition to verdict.

## What an experiment answers

Whether one edit to a `SKILL.md` changed what a coding agent writes, under one host and one model,
on one case. The answer is one [verdict](glossary.md), with each [condition](glossary.md)'s rate as
k of n with its interval, each [contrast](glossary.md) with its interval, and every excluded run
with its reason.

## 1. Define the experiment

_Filled by BUILD-06 (experiment and pre-registration): the experiment directory, and how to name
the skill, case, model, host and conditions._

## 2. Build the conditions

_Filled by BUILD-02 (workspace and conditions): how no-skill, real, seeded and placebo conditions
are built from one `SKILL.md`, and how each host is given its skill._

## 3. Choose the instruments

_Filled by BUILD-05 (instruments): the instruments that ship with the harness, their parameters,
and how to add one._

## 4. Pre-register

_Filled by BUILD-06: writing the pre-registration, its positive-control minimum and attrition
tolerance, and writing an amendment._

## 5. Run

_Filled by BUILD-07 (runner), with the host-specific parts from BUILD-04 (Claude Code and Codex)
and BUILD-12 and BUILD-13 (Antigravity CLI and Muse Code): the one command that runs an
experiment, and what it leaves on disk._

## 6. Check the runs

_Filled by BUILD-01 (run record) and BUILD-03 (integrity): reading a run record, the outcome
classes, and why a run was excluded._

## 7. Read the verdict

_Filled by BUILD-08 (analysis): rates, contrasts, the comparability gate, the attrition flag, the
positive-control gate, and the four verdicts._

## 8. Report and re-score

_Filled by BUILD-09 (report and re-score): producing a report from the records, recomputing it,
and re-scoring after the scoring code changes._
