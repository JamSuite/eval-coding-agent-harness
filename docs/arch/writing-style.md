# Writing style

[⬑ Back to arch TOC](./index.md)

Every document in this repository follows these rules: the docs under `docs/`, specs, ADRs, the
README, code comments and commit messages. Adapted from the reference repository's
`docs/writing-style.md`, which was written for published articles.

## Audience

Software engineers who contribute to the harness or use it to test a skill. Assume they know
software and TypeScript. Do not assume they know evaluation terms; link those to
[`glossary.md`](glossary.md) on first use in a document.

## Rules

- **Lead with the point.** The first sentence of a document or section says what it gives the
  reader. No introductions about AI, testing or the industry.
- **Use direct prose.** Short declarative sentences. Use commands only for procedures.
- **Name checkable facts.** A version, a path, a command, a count, a threshold, an outcome class.
  Replace vague wording with something a reader could verify.
- **One idea at a time.** Short paragraphs. Split a sentence that carries several qualifications.
- **State each fact once.** Link to where a fact lives instead of restating it. `PROMPTS.md` →
  Shared context holds the project's rules; the [glossary](glossary.md) holds its terms; beads hold
  status. A copy goes stale the day its source changes.
- **Plain words.** Use a technical term only when it is more precise, and then define it once.
- **Show both sides of a distinction.** "The skill was invoked" versus "the skill's body changed
  the output"; "could not read" versus "found nothing".
- **Keep status out of docs.** Status lives in beads. A doc says what is true of the design, not
  how far the work has got.
- **Link back to the index.** Every page under `docs/arch/` except `index.md` has
  `[⬑ Back to arch TOC](./index.md)` on the line after its title, with the path adjusted in a
  subfolder.
- **Approachable tone.** An experienced engineer explaining work to another. Not formal, not
  promotional, not chatty.

## Avoid

- generic openings and motivational conclusions;
- rhetorical questions;
- decorative analogies;
- inflated words such as "revolutionary", "seamless" or "robust";
- stock phrases such as "let's dive in", "at its core" or "the key takeaway";
- long bullet lists where prose is clearer;
- bold on every important phrase.

## Before committing a doc

1. Write its point in one sentence.
2. Cut anything that does not support, qualify or apply that point.
3. Replace vague wording with named facts.
4. Replace each restated fact with a link to its source.
5. Check that nothing in it contradicts `PROMPTS.md` → Shared context.
