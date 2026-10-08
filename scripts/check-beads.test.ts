import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, it } from "node:test";

import { checkBeads, readIssues, readSpecs, type Issue } from "./check-beads.ts";

const SCRIPT = join(import.meta.dirname, "check-beads.ts");

function bead(title: string, status: string, labels: string[]): Issue {
    return { id: `eh-${title.slice(0, 5)}`, title, status, labels };
}

const specBead = (nn: string, status: string) => bead(`SPEC-${nn} — Spec: x`, status, ["prompt"]);
const buildBead = (nn: string, status: string) => bead(`BUILD-${nn} — Build: x`, status, ["prompt"]);
const taskBead = (id: string, status: string, label = `spec-${id.slice(0, 2)}`) => bead(`${id} — a task`, status, [label]);

// Spec 07 has tasks 07.1 and 07.2.
const specs = new Map([["07", new Set(["07.1", "07.2"])]]);

describe("checkBeads", () => {
    it("passes an approved spec whose every task has a bead", () => {
        const issues = [specBead("07", "closed"), buildBead("07", "open"), taskBead("07.1", "open"), taskBead("07.2", "closed")];
        assert.deepEqual(checkBeads(issues, specs), []);
    });

    it("ignores a spec that is not yet approved", () => {
        const issues = [specBead("07", "in_progress"), buildBead("07", "open")];
        assert.deepEqual(checkBeads(issues, specs), []);
    });

    it("fails when an approved spec has a task with no bead", () => {
        const issues = [specBead("07", "closed"), buildBead("07", "open"), taskBead("07.1", "open")];
        assert.deepEqual(checkBeads(issues, specs), ["spec 07 is approved but task 07.2 has no bead"]);
    });

    it("fails when an approved spec has no spec file", () => {
        const issues = [specBead("08", "closed")];
        assert.deepEqual(checkBeads(issues, specs), ["spec 08 is approved but docs/specs/08-*/spec.md does not exist"]);
    });

    it("does not count a deleted bead as a task's bead", () => {
        const issues = [specBead("07", "closed"), taskBead("07.1", "open"), taskBead("07.2", "tombstone")];
        assert.deepEqual(checkBeads(issues, specs), ["spec 07 is approved but task 07.2 has no bead"]);
    });

    it("fails when a spec-NN bead names a task the spec does not have", () => {
        const issues = [taskBead("07.9", "open")];
        assert.deepEqual(checkBeads(issues, specs), ["bead eh-07.9 names task 07.9, which docs/specs/07-*/spec.md does not have"]);
    });

    it("fails when a bead's task ID and its spec-NN label disagree", () => {
        const issues = [taskBead("07.1", "open", "spec-08")];
        assert.deepEqual(checkBeads(issues, specs), ["bead eh-07.1 names task 07.1 but is labelled spec-08"]);
    });

    it("ignores discovered work, whose title is not a task ID", () => {
        const issues = [bead("Runner drops stderr", "open", ["spec-07"])];
        assert.deepEqual(checkBeads(issues, specs), []);
    });

    it("fails when a closed BUILD bead has open task beads", () => {
        const issues = [specBead("07", "closed"), buildBead("07", "closed"), taskBead("07.1", "closed"), taskBead("07.2", "blocked")];
        assert.deepEqual(checkBeads(issues, specs), ["BUILD-07 is closed but task bead eh-07.2 (07.2) is blocked"]);
    });

    it("passes a closed BUILD bead whose task beads are all closed", () => {
        const issues = [specBead("07", "closed"), buildBead("07", "closed"), taskBead("07.1", "closed"), taskBead("07.2", "closed")];
        assert.deepEqual(checkBeads(issues, specs), []);
    });
});

describe("readSpecs", () => {
    it("reads each task ID from a spec's Task Breakdown", () => {
        const dir = mkdtempSync(join(tmpdir(), "check-beads-"));
        mkdirSync(join(dir, "07-runner"));
        writeFileSync(
            join(dir, "07-runner", "spec.md"),
            [
                "# 07 — Runner",
                "",
                "- **AC-1** not a task",
                "",
                "## Task Breakdown",
                "",
                "- **07.1** First.",
                "  **Depends on:** none",
                "- **07.2** Second.",
            ].join("\n"),
        );
        writeFileSync(join(dir, "README.md"), "# Specs\n");
        assert.deepEqual(readSpecs(dir), new Map([["07", new Set(["07.1", "07.2"])]]));
    });

    it("returns no specs when the directory does not exist", () => {
        assert.deepEqual(readSpecs(join(tmpdir(), "check-beads-missing-dir")), new Map());
    });
});

describe("readIssues", () => {
    it("reads one issue per JSONL line as br writes it", () => {
        const dir = mkdtempSync(join(tmpdir(), "check-beads-"));
        const file = join(dir, "issues.jsonl");
        writeFileSync(
            file,
            '{"id":"eh-1","title":"07.1 — x","status":"open","labels":["spec-07"],"dependencies":null}\n{"id":"eh-2","title":"P1","status":"closed"}\n',
        );
        assert.deepEqual(readIssues(file), [
            { id: "eh-1", title: "07.1 — x", status: "open", labels: ["spec-07"] },
            { id: "eh-2", title: "P1", status: "closed", labels: [] },
        ]);
    });
});

describe("check-beads command", () => {
    function repo(issues: Issue[]): string {
        const dir = mkdtempSync(join(tmpdir(), "check-beads-"));
        mkdirSync(join(dir, ".beads"));
        mkdirSync(join(dir, "docs", "specs", "07-runner"), { recursive: true });
        writeFileSync(join(dir, "docs", "specs", "07-runner", "spec.md"), "- **07.1** Only task.\n");
        writeFileSync(join(dir, ".beads", "issues.jsonl"), issues.map((i) => JSON.stringify(i)).join("\n") + "\n");
        return dir;
    }

    it("exits 0 and prints nothing when the beads match the specs", () => {
        const cwd = repo([specBead("07", "closed"), taskBead("07.1", "open")]);
        assert.equal(execFileSync("node", [SCRIPT], { cwd, encoding: "utf8" }), "");
    });

    it("exits 1 and lists each problem on stderr", () => {
        const cwd = repo([specBead("07", "closed")]);
        assert.throws(
            () => execFileSync("node", [SCRIPT], { cwd, encoding: "utf8", stdio: "pipe" }),
            (err: { status: number; stderr: string }) => err.status === 1 && err.stderr === "check-beads: spec 07 is approved but task 07.1 has no bead\n",
        );
    });
});
