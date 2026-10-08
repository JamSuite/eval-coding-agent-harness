# Contributing to eval-coding-agent-harness

Thank you for considering a contribution. Bug reports, questions and pull requests are all welcome.

## Ground rules

- Be respectful and professional.
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md).
- Give constructive feedback.
- Keep discussions on the topic at hand.

## Response time

This is a small project with other priorities. A reply to an issue or pull request may take a
while.

## Types of contribution

### Bug reports

Open an issue that includes:

- what went wrong, in a sentence or two;
- the steps to reproduce it;
- what you expected and what happened instead;
- any error output, and the host and version involved (`claude --version`, `codex --version`, …).

### Pull requests

- Branch from `main`.
- Follow the rules in [`CLAUDE.md`](CLAUDE.md) and the Shared context in [`PROMPTS.md`](PROMPTS.md).
- Write the test first, and watch it fail before writing the code.
- Update the docs your change affects.
- Name the bead or issue the change addresses.

## Setup

Follow [Setup](README.md#setup) in the README: open the repository in its devcontainer and log in
to each host. Unit tests need no login.

## Workflow

The project is built from [`PROMPTS.md`](PROMPTS.md), one prompt at a time, and tracked in beads
with `br`. In short:

1. **Spec.** No harness code is written without an approved spec under `docs/specs/`.
2. **Build.** Each spec task is built test first, and every control gets a test that seeds the
   breakage it detects.
3. **Done.** The quality gate passes, the work is committed, and its bead is closed with the
   commit hash.

[`docs/arch/spec-process.md`](docs/arch/spec-process.md) describes a working session. Anything you
find outside your change goes in a new bead, not in the change.

Run workspaces must never load this repository's instruction files. Read the rule in
[`CLAUDE.md`](CLAUDE.md) before touching how workspaces are created.

## Code review

1. Open your pull request.
2. Address the reviewer's feedback.
3. Once it is approved, a maintainer merges it.

## Communication

- Issues: bug reports and feature requests.
- Pull requests: code changes.

## Additional notes

- Contributors of every skill level and background are welcome.
- If you are unsure about something, ask.

## License

By contributing, you agree that your contributions are licensed under the project's
[Apache License 2.0](LICENSE.md).
