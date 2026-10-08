// Checks the approved specs against the task beads, as PROMPTS.md -> Shared
// context -> Tracking requires. Reads the committed .beads/issues.jsonl, so it
// needs no `br` and runs in CI.
//
// Spec NN is approved once its SPEC-NN prompt bead is closed. A task bead is
// one labelled spec-NN whose title starts with a task ID NN.k; any other
// spec-NN bead is discovered work and is not checked.

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

export interface Issue {
    id: string;
    title: string;
    status: string;
    labels: string[];
}

// Spec number -> the task IDs in its Task Breakdown.
export type Specs = Map<string, Set<string>>;

const TASK_TITLE = /^(\d\d)\.\d+(?=\D|$)/;
const TASK_LINE = /^- \*\*(\d\d\.\d+)\*\*/gm;
const SPEC_DIR = /^(\d\d)-/;

// A deleted bead no longer stands for anything.
const exists = (issue: Issue) => issue.status !== "tombstone";

function promptBead(issues: Issue[], prompt: string): Issue | undefined {
    return issues.find((issue) => exists(issue) && issue.labels.includes("prompt") && issue.title.startsWith(`${prompt} `));
}

export function checkBeads(issues: Issue[], specs: Specs): string[] {
    const problems: string[] = [];
    const tasks = issues.flatMap((issue) => {
        const match = TASK_TITLE.exec(issue.title);
        return match && exists(issue) ? [{ issue, task: match[0], nn: match[1] ?? "" }] : [];
    });

    for (const { issue, task, nn } of tasks) {
        const label = issue.labels.find((l) => l.startsWith("spec-"));
        if (label === undefined) continue;
        if (label !== `spec-${nn}`) {
            problems.push(`bead ${issue.id} names task ${task} but is labelled ${label}`);
        } else if (!specs.get(nn)?.has(task)) {
            problems.push(`bead ${issue.id} names task ${task}, which docs/specs/${nn}-*/spec.md does not have`);
        }
    }

    const specNumbers = new Set([...specs.keys(), ...issues.flatMap((i) => /^SPEC-(\d\d) /.exec(i.title)?.[1] ?? [])]);
    for (const nn of [...specNumbers].sort()) {
        const ofSpec = tasks.filter((t) => t.nn === nn && t.issue.labels.includes(`spec-${nn}`));

        if (promptBead(issues, `SPEC-${nn}`)?.status === "closed") {
            const specTasks = specs.get(nn);
            if (specTasks === undefined) {
                problems.push(`spec ${nn} is approved but docs/specs/${nn}-*/spec.md does not exist`);
            } else {
                for (const task of specTasks) {
                    if (!ofSpec.some((t) => t.task === task)) problems.push(`spec ${nn} is approved but task ${task} has no bead`);
                }
            }
        }

        if (promptBead(issues, `BUILD-${nn}`)?.status === "closed") {
            for (const { issue, task } of ofSpec) {
                if (issue.status !== "closed") problems.push(`BUILD-${nn} is closed but task bead ${issue.id} (${task}) is ${issue.status}`);
            }
        }
    }
    return problems;
}

export function readIssues(file: string): Issue[] {
    return readFileSync(file, "utf8")
        .split("\n")
        .filter((line) => line.trim() !== "")
        .map((line) => {
            const raw = JSON.parse(line) as Partial<Issue>;
            return { id: raw.id ?? "", title: raw.title ?? "", status: raw.status ?? "", labels: raw.labels ?? [] };
        });
}

export function readSpecs(dir: string): Specs {
    const specs: Specs = new Map();
    if (!existsSync(dir)) return specs;
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
        const nn = SPEC_DIR.exec(entry.name)?.[1];
        const file = join(dir, entry.name, "spec.md");
        if (!entry.isDirectory() || nn === undefined || !existsSync(file)) continue;
        const ids = [...readFileSync(file, "utf8").matchAll(TASK_LINE)].map((m) => m[1] ?? "");
        specs.set(nn, new Set(ids.filter((id) => id.startsWith(`${nn}.`))));
    }
    return specs;
}

if (import.meta.main) {
    const problems = checkBeads(readIssues(".beads/issues.jsonl"), readSpecs("docs/specs"));
    for (const problem of problems) process.stderr.write(`check-beads: ${problem}\n`);
    process.exitCode = problems.length === 0 ? 0 : 1;
}
