---
name: beads-sdd
description: How to track this repository's prompts, specs, tasks and discovered work with beads_rust (br). Use when starting, finishing or blocking a prompt from PROMPTS.md, when a spec is finished or approved, when working a BUILD prompt's task beads, or when finding work outside the current prompt.
---

# beads-sdd

The rules are in `PROMPTS.md` → Shared context → Tracking. This skill gives the `br` commands
that apply each rule. It does not restate the rules.

Before any command: `export RUST_LOG=error`. Parse only `--json` output; plain output changes with
the terminal.

## Who sees this skill

Only the Claude Code session that builds this repository. It lives in this repository's
project-scope skill directory and nowhere else: not in `~/.claude/skills`, not as a plugin, not in
`/workspaces`. Run workspaces are created outside this repository, so no host under test can load
it. Never copy it to a user-scope or shared directory.

## Why not upstream's `beads@beads-rust` plugin

The plugin installs at user scope, in `~/.claude`. That is the same configuration directory every
Claude Code run under test reads, so the plugin's skill would be loaded by those runs: an
instruction file the host loads on its own, which is one of the rivals the harness rules out. Its
content is also a general `br` guide; the project needs the mapping from its own Tracking rules to
commands. For general `br` help, run `br <command> --help` or `br robot-docs guide`.

## Bead naming

| Bead              | Title starts with | Labels              | Created by                    |
| ----------------- | ----------------- | ------------------- | ----------------------------- |
| One per prompt    | `P1`, `SPEC-03`…  | `prompt`            | P0B                           |
| One per spec task | `03.2`            | `spec-03`           | the session, on spec approval |
| Discovered work   | free text         | `spec-NN`/`harness` | the session that found it     |

IDs look like `eh-<slug>-<hash>`. Pass `--slug` so they stay readable: `p1`, `03-2`.

## Next

```sh
br ready --label prompt --json --brief | jq -r '.[].title'
```

Take the prompt that comes first in PROMPTS.md's "Prompts in order" table. Read its full bead
with `br show <id>`.

## State

Start:

```sh
br update <id> --status in_progress
```

Done, after the gate passes and the work is committed:

```sh
br close <id> --reason "Done in $(git rev-parse --short HEAD)"
git add .beads/issues.jsonl && git commit -m "Close <PROMPT-ID> bead"
```

The close changes `issues.jsonl` after the hash exists, so it always needs its own small commit.

Cannot finish:

```sh
br update <id> --status blocked
br comments add <id> "Blocked: <reason>"
```

Then commit `issues.jsonl` and stop.

## Specs

The spec's `Tracking:` line names the BUILD-NN bead ID, from
`br list --label prompt --json --fields id,title | jq -r '.issues[] | select(.title|startswith("BUILD-NN ")) | .id'`.

Finished, awaiting review:

```sh
br update <SPEC-NN id> --add-label awaiting-review
```

The bead stays in progress. On the user's approval:

```sh
br update <SPEC-NN id> --remove-label awaiting-review
br close <SPEC-NN id> --reason "Approved; spec in <hash>"
```

Then one bead per task `NN.k`, in task order:

```sh
br create "NN.k — <a few words>" --type task --labels spec-NN --parent <BUILD-NN id> \
    --slug NN-k -d "Task NN.k in docs/specs/NN-name/spec.md."
br dep add <NN.k id> <NN.j id>     # once per entry in the task's Depends on
```

The description points to the spec; never copy the task text or Verify command into the bead.

## Building

```sh
br ready --label spec-NN --json --brief | jq -r '.[].title'
```

Work them test first. Close each with `br close <id> --reason "Done in <hash>"` once its Verify
command passes. When every `spec-NN` task bead is closed, close the BUILD-NN bead the same way.

## Discovered work

Before creating, check it is not already a task or a bead:
`br search "<words>" --json | jq -r '.issues[].title'`.

```sh
br create "<what is wrong or missing>" --type task --labels spec-NN \
    --deps discovered-from:<current bead id> -d "<where, and how it was found>"
```

Use `--labels harness` when it belongs to no spec, and `--type bug` for a defect. When a spec
takes it in as task `NN.k`:

```sh
br close <id> --reason "Became task NN.k"
```

## Committing

`br` writes `.beads/issues.jsonl` after every change and never runs git. Stage `.beads/` with the
work it describes; `.beads/.gitignore` keeps the database and its sidecars out. Before staging,
`br sync --flush-only` confirms the export is current.
