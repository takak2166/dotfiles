---
name: plan
description: Create a phased implementation plan from an ADR (repository path, Notion, Scrapbox, or other sources) with review and branching rules. Use when you have an ADR and need a reviewable, phase-split plan.
disable-model-invocation: true
---

# Plan
A skill to create an implementation plan based on an ADR.

## Usage
```
/plan -adr [ADR URL or path]
```

## Steps
1. **Obtain the ADR text**
   - **Repository path** (relative/absolute in the workspace): read with `Read` (and `Glob` / `Grep` to locate the file if needed).
   - **Notion, Scrapbox, or another service exposed via MCP**: fetch using the **MCP server** for that service. Before calling a tool, read that tool’s schema (descriptor JSON under the client’s MCP tools path, or equivalent). **Do not use `curl` or unauthenticated HTTP** for URLs that require login, OAuth, or cookies—those cases must go through MCP (or the fallback below).
   - **If MCP is unavailable, misconfigured, or the URL is not covered**: ask the user to paste the ADR body, provide a repo path, or fix/enable the MCP server—do not guess missing content.
1. **Review the ADR**
   - Check differences between ADR content and current implementation.
   - Summarize your understanding in bullet points.
1. **Produce the implementation plan** using the **Output template** and **Phase rules** below. Every phase must satisfy **Phase rules**. The document **must** include a section titled **Development Process** whose bullets cover every item under **Development Process** (below) verbatim or as a faithful summary—do not omit any item.

### Phase rules
- Each phase must begin with a step to "confirm the development process"
- **Line budget:** per phase, total **added + deleted** lines of code (exclude blank lines and comments) must not exceed **500**. When measuring after work, use the same notion as `git diff --stat` (sum of insertions and deletions across files in that phase’s scope). When estimating before coding, treat this as a conservative upper bound on that total.
- Each phase should be independently testable and verifiable
  - Include verification procedures and expected results
- Specify what to implement and which files to create/modify in each phase

### Development Process
- Before each phase: run `git fetch` (default remote, typically `origin`), ensure local `main` is up to date with the remote (e.g. `git switch main` then `git pull`), then create a new branch from that `main` using `git switch -c`
- After completing each phase implementation, request a review from the user via chat
- If modifications are needed after review, make corrections and request review again
- Do not proceed to the next phase without receiving approval comments from the user
- When proceeding to the next phase, stage the diff with `git add` and follow the **create-commit-en** skill (`create-commit-en/SKILL.md` alongside other skills, or invoke `/create-commit-en` where supported)

### Output template
Use Markdown with at least the following shape (add subsections as needed):

```markdown
# Implementation plan

## ADR summary
- (bullets)

## Gap analysis (ADR vs current code)
- (bullets)

## Development Process
- (paste or summarize every bullet from **Development Process** above)

## Phase 1
- **Goal:**
- **Files to create/modify:**
- **Steps:** (include opening "confirm the development process")
- **Verification:** (procedure and expected results)
- **Estimated change size:** (how this stays within the line budget)

## Phase 2
- ...
```

## Restrictions
- Do not execute shell commands other than `git fetch`, `git pull`, `git switch`, `git add`, `git diff`, `git diff --staged`, `git diff --stat`, `git log`, `git status`, and `git commit` (with `-m`, as in **create-commit-en**) when following this skill’s workflow
- Do not use `curl`, `wget`, or generic HTTP clients to fetch ADRs that require authentication; use MCP or user-provided text/paths as described in **Obtain the ADR text**
