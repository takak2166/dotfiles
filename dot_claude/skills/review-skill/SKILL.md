---
name: review-skill
description: Review a SKILL.md file for discovery, scope, clarity, structure, context efficiency, and execution safety. Use when reviewing agent skills, refactoring SKILL.md files, or when the user asks for feedback on a skill.
disable-model-invocation: true
---

# Review Skill

Follow **Restrictions**, **Steps**, and **Review Output** below.

**Role:** Act as a strict but constructive skill-design reviewer.

## Success criteria (SMART-oriented)

- **Specific & measurable:** The reply includes **## Findings** (or **No findings.**) and **## Strengths**, each finding uses the four required labels, and severities match the definitions in **Steps**.
- **Achievable:** You read the target file (and linked supporting files only as required by **Steps**) before judging.
- **Relevant:** Findings address discovery, instructions, structure, outputs, safety, or context efficiency—not general code style unrelated to the skill.
- **Time-bound (session):** Finish in one pass for the given path; if the target is truncated or unreadable in part, state that limitation in the reply instead of guessing.

## Restrictions

- **Read-only inspection:** Limit workspace inspection to `Read` / `ReadFile`, `Glob`, and `Grep` / ripgrep (`rg`), or the client’s read-only equivalents. Use read-only semantic search only to locate candidate paths, then load those paths with `Read`. Confine the entire review pass to that read-only inspection surface.
- **Preserve the target:** Keep the target skill unchanged unless the user explicitly asks for edits.
- **Evidence-based findings:** Ground every finding in text you actually read. When something was not read, is missing, or is unclear from the available text, state that plainly and reserve judgment rather than inferring undocumented behavior.

## Usage

```
/review-skill [path to SKILL.md or skill directory]
```

Accept a path relative to the workspace root, a path to `SKILL.md`, or a skill directory. Some clients pass `@`-style references; resolve them to a real path before existence checks.

Example invocations (`disable-model-invocation` is true; attach or run the skill explicitly):

- `/review-skill @dot_claude/skills/draft-pr` or `/review-skill path/to/SKILL.md`

Resolve the target and follow **Steps** (constraints above apply to the whole workflow).

## Steps

1. If no path is provided, or the path is empty or whitespace-only, ask the user for the target skill directory or `SKILL.md` path and stop.
1. If the user asks you to review content that is clearly not a skill document (for example application source with no skill intent, or a topic unrelated to agent skills), reply briefly that this workflow reviews skill documents, and ask for a path to `SKILL.md` or a skill directory—or stop if they clarify.
1. Resolve the target:
   - If the argument is a directory, review `<directory>/SKILL.md`
   - If the argument is a file, treat that file as the skill document to review (the basename does not need to be `SKILL.md`)
   - If the resolved path does not exist, or the file cannot be read as text, or the argument is too vague to map to a single path: use read-only semantic search to identify candidate paths; choose one clear match or ask the user; if you then have an existing readable target, continue; otherwise tell the user and stop
1. Read the target skill file with `Read` (`ReadFile` in some clients). If only a partial view is available (client truncation or huge file), review what you can see and add a **Major** or **Minor** finding (or a sentence under **## Findings**) describing the validation gap.
1. If the target lives under a parent directory that groups multiple skills (for example `.../skills/<skill-name>/SKILL.md`):
   - Use `Glob` on that parent to list sibling `SKILL.md` paths (for example `*/SKILL.md`).
   - When at least one sibling exists besides the target, `Read` at least one sibling far enough to compare frontmatter (`name`, `description`) and top-level heading structure; read more siblings only when needed for the review.
   - Use this comparison only to flag material divergence from nearby skills (for example inconsistent `description` tone or top-level heading patterns) as a Major or Minor finding when it would affect discovery or maintenance; if the target aligns with sibling conventions, do not add a finding solely because siblings were read.
   - If there is no such parent or no sibling exists, skip this step.
   - Do not load every skill in the repository unless the user asks for a repo-wide audit
1. If the main skill links directly to one-level-deep supporting files such as `reference.md`, `examples.md`, or `scripts/*`, read only the files needed to validate claims in the main skill (using `Read`). Use `Glob` or `Grep` (ripgrep / `rg`) when needed to locate or search those files
1. Review the skill in the following priority order:
   1. Discovery and scope
      - `name` is specific, lowercase, hyphenated, and not vague
      - `description` explains both WHAT the skill does and WHEN to use it
      - Trigger scenarios are specific enough for discovery
      - The skill scope is narrow enough to avoid unrelated tasks
   2. Structure and maintainability
      - The file uses YAML frontmatter and a Markdown body
      - The main structure is readable with Markdown headings
      - Markdown is the default structure for human-maintained sections
      - XML is used only where strict boundaries help the model parse inputs, outputs, or examples
      - The main `SKILL.md` stays concise; move long details to directly linked reference files when needed
      - Terminology is consistent throughout
   3. Instruction quality
      - Steps are clear, direct, and ordered
      - Important constraints appear near the top
      - Fragile rules include brief rationale when it helps correct execution
      - Instructions do not contradict each other
      - The skill does not mix too many unrelated objectives
   4. Output and examples
      - Expected output or response structure is explicit when the task needs it
      - Examples are concrete and clearly separated from the main instructions
      - If XML is used, it improves precision instead of adding noise
   5. Tooling, safety, and feasibility
      - Required tools or commands are named explicitly
      - Restrictions do not conflict with the steps
      - The workflow is executable in the intended environment
      - The skill avoids dangerous, impossible, or underspecified instructions
   6. Context efficiency
      - The file avoids redundant explanation the agent likely already knows
      - Important rules are near the top
      - Background detail is loaded progressively instead of packed into `SKILL.md`
1. Before writing the user-visible reply, assign each issue to `Critical`, `Major`, or `Minor` internally; keep chain-of-thought out of the final message unless the user explicitly asks for it.
1. Produce findings first, ordered by severity:
   - `Critical`: likely to cause wrong behavior, unsafe behavior, or failed execution
   - `Major`: materially harms discovery, clarity, maintainability, or review quality
   - `Minor`: consistency, wording, or optional improvements
1. Compose the final reply per **Review Output** and [`reference.md`](reference.md) (field labels, subsection layout, multi-finding separators, no-findings layout, and **## Strengths**).

## Review Output

Canonical rules for **## Findings** and **## Strengths**; [`reference.md`](reference.md) has copy-paste templates, `<example>`-wrapped samples, and a good-versus-weak **Suggested fix** contrast.

- Read [`reference.md`](reference.md) in this skill directory when you need copy-paste Markdown templates, the no-findings layout, multi-finding separators, or the worked examples.
- **Length:** Keep **## Strengths** to about 2–5 bullets. Keep each finding’s four fields to roughly one or two sentences unless the issue is inherently complex; do not paste large chunks of the target skill into the review.
- **Grounding:** When a finding depends on exact wording, quote a **short** snippet from the target (or point to a section heading) so the reader can verify the claim. If you lack a quote because text was unavailable, say that in **Why it matters:** or **Problem:**.
- **Uncertainty:** When evidence is insufficient to decide whether something is intentional or a defect, state explicitly that you **cannot determine** or **cannot judge** from the material read (briefly say what was missing, e.g. unseen sections or ambiguous wording). Frame **Suggested fix:** as a question or optional improvement rather than asserting a defect. When only part of the issue is uncertain, separate verified observations from what remains undetermined.
- Under **## Findings**, include only `### Critical`, `### Major`, or `### Minor` subsections that have at least one finding; **omit** empty severity subsections (do not leave a heading with no content). Copy only the severity blocks you need—do not paste empty `### Critical` / `### Major` / `### Minor` headings.
- In the actual response, **replace** every `…` placeholder in templates with real text; do not output literal `…` as the finding content.
- Each finding uses exactly these four labels: **Affected section:**, **Problem:**, **Why it matters:**, **Suggested fix:**
- When multiple findings appear under the same `### Critical`, `### Major`, or `### Minor` subsection, separate consecutive four-field blocks as specified in [`reference.md`](reference.md): use **`Finding 2`**, **`Finding 3`**, … after the first block, or use `---` between blocks; do not mix **`Finding N`** and `---` in the same response.
- If there are no findings at any severity, state that explicitly under **## Findings** (for example a single line **No findings.**), mention any residual risks or validation gaps if relevant, and omit the `### Critical` / `### Major` / `### Minor` subsections entirely.
- End with **## Strengths** and a short bullet list.
- **Optional prefill:** If the client allows steering the first tokens, you may prefill the assistant turn with `## Findings` to lock Markdown structure (do not prefill finding content).

## Notes

- Full response templates and examples live in [`reference.md`](reference.md) next to this file
- **Review Output** and [`reference.md`](reference.md) define the final reply structure; **Steps** end by pointing to them so formatting rules stay in one place
- **Restrictions** comes immediately after **Role** (before **Usage** and **Steps**) so read-only rules are visible first; other skills in this repo may place **Restrictions** last—here the order is intentional
- `disable-model-invocation: true` in frontmatter means clients that support this flag will not auto-invoke the skill; attach or invoke it explicitly when needed
- Default to Markdown headings for overall structure because `SKILL.md` is maintained by humans
- XML is optional; recommend it only when it clearly improves boundaries between instructions, examples, inputs, or outputs
- Do not treat "uses Markdown instead of XML" as a problem by itself
- Review the current file contents instead of relying on memory or prior drafts
- **Maintainer checks:** After changing this skill, spot-check at least five cases (missing path, bad path, minimal `SKILL.md`, skill with `reference.md`, sibling under `skills/`), then re-check one prior success path for regression
