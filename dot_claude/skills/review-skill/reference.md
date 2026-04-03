# Review output — templates and examples

Use these when composing the final response for **review-skill**. Requirements in `SKILL.md` **Review Output** always win if anything conflicts.

## Full template (all severities)

Copy only the severity blocks you need. Do not paste empty `### Critical` / `### Major` / `### Minor` headings.

In the actual response, **replace** every `…` placeholder with real text; do not output literal `…` as the finding content.

```markdown
## Findings

### Critical
- **Affected section:** … (e.g. frontmatter, Steps, Restrictions)
- **Problem:** …
- **Why it matters:** …
- **Suggested fix:** …

### Major
- **Affected section:** …
- **Problem:** …
- **Why it matters:** …
- **Suggested fix:** …

### Minor
- **Affected section:** …
- **Problem:** …
- **Why it matters:** …
- **Suggested fix:** …

## Strengths
- …
```

## No findings

```markdown
## Findings

**No findings.**

## Strengths
- …
```

## Multiple findings in the same severity

Within a single `### Critical`, `### Major`, or `### Minor` subsection, repeat the full four-field block for each finding. After the first block, separate the next finding from the previous one with a blank line and a bold line **`Finding 2`**; use **`Finding 3`**, **`Finding 4`**, and so on for additional findings in that same subsection. The first finding in a subsection does not need a **`Finding 1`** line.

Alternatively, use a horizontal rule (`---`) between consecutive four-field blocks instead of **`Finding N`** lines. Do not mix **`Finding N`** and horizontal rules in the same response.

## Suggested fix — weak vs strong (same underlying issue)

Use **Suggested fix:** to give an actionable, specific change. Avoid vague advice.

<example type="contrast" title="Weak vs strong Suggested fix">

**Weak (too vague):**

- **Suggested fix:** Improve the steps.

**Strong (specific):**

- **Suggested fix:** Add a numbered sub-step under **Steps**: use only `Read` / `Glob` for inspection; keep shell and network off the critical path—so execution matches **Restrictions**.

</example>

## Few-shot examples (placeholders fully replaced)

<example type="Major" title="One Major finding (baseline)">

Below is a **complete** sample from `## Findings` through `## Strengths` with **one** Major finding.

```markdown
## Findings

### Major

- **Affected section:** frontmatter / description
- **Problem:** Trigger scenarios are vague
- **Why it matters:** The agent may not load this skill when the user needs it, or may apply it in the wrong context.
- **Suggested fix:** Add concrete trigger phrases and a one-line "Use when …" clause that matches real chat prompts.

## Strengths

- Frontmatter includes `name` and `description`, giving a baseline for discovery.
- The main workflow is organized with Markdown headings and numbered steps.
```

If you only need the Major subsection (for example you are appending to an existing response), use the same four-field block under `### Major`:

```markdown
### Major

- **Affected section:** frontmatter / description
- **Problem:** Trigger scenarios are vague
- **Why it matters:** The agent may not load this skill when the user needs it, or may apply it in the wrong context.
- **Suggested fix:** Add concrete trigger phrases and a one-line "Use when …" clause that matches real chat prompts.
```

</example>

<example type="Critical" title="Critical — contradictory instructions">

```markdown
## Findings

### Critical

- **Affected section:** Restrictions vs Steps
- **Problem:** **Restrictions** forbids using the shell, but **Steps** instruct running `npm test` via the terminal.
- **Why it matters:** The agent cannot follow both; execution will fail or violate safety expectations.
- **Suggested fix:** Either remove shell commands from **Steps** and replace with read-only verification, or narrow **Restrictions** with an explicit, scoped exception that matches the intended environment.

## Strengths

- Frontmatter identifies the skill name and a clear primary use case.
```

</example>

<example type="Minor" title="Minor — consistency">

```markdown
## Findings

### Minor

- **Affected section:** Terminology (body)
- **Problem:** The doc alternates between "sub-agent" and "subagent" for the same concept.
- **Why it matters:** Small inconsistencies make maintenance and search harder.
- **Suggested fix:** Pick one spelling (for example "subagent") and use it throughout.

## Strengths

- Steps are ordered and easy to scan.
```

</example>

<example type="edge" title="Edge — partial read / truncation">

```markdown
## Findings

### Major

- **Affected section:** Validation coverage
- **Problem:** Only the first portion of `SKILL.md` was visible; the rest was not available to read.
- **Why it matters:** Findings below may miss issues in the unseen portion.
- **Suggested fix:** Re-run the review in an environment that returns the full file, or split the skill into a shorter `SKILL.md` plus `reference.md`.

## Strengths

- The visible section uses clear Markdown headings.
```

</example>
