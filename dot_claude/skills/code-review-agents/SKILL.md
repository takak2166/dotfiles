---
name: code-review-agents
description: >-
  Perform multi-perspective code review using 8 specialized analysis agents in
  parallel (language spec, refactoring, DDD, clean architecture, security,
  performance, TDD, observability) plus 1 integration agent that synthesizes
  all findings. Use when performing thorough code reviews, PR reviews, or
  when the user asks for a comprehensive code review.
---

# Code Review Agents

8 specialized analysis agents (parallel) → 1 integration agent (sequential).

## Usage

```
/code-review-agents [PR number | base branch]
```

- PR number: review the PR diff (e.g., `/code-review-agents 42`)
- Base branch: review diff against specified branch (e.g., `/code-review-agents main`)
- No argument: review staged changes (fall back to `git diff HEAD` if nothing staged)

## Steps

1. **Determine review target**
   - **Disambiguation:** If the argument is a bare integer (e.g. `42`), treat it as a **PR number** by default. Otherwise treat it as a **base branch name** for `git diff`. If the intent is ambiguous (e.g. a branch named like a number), ask the user before proceeding.
     - If the argument is a bare integer, run `git branch --list <arg>`:
       - If it returns a matching branch, ask the user: “`<arg>` は PR 番号ですか？それともブランチ名ですか？”
       - If it returns nothing, proceed as PR number.
   - PR number → `gh pr diff <number>`
   - Branch name → `git diff <branch>...HEAD`
   - No argument → `git diff --staged` (fall back to `git diff HEAD`)
     - `git diff HEAD` is intended to review **unstaged changes on tracked files** relative to `HEAD`.
     - Note: **untracked files are not included** in `git diff HEAD`.
       - If `git diff --staged` and `git diff HEAD` are both empty, also run `git status --porcelain` to detect untracked changes. If only untracked files exist, treat them as changed files (adds) and include their full contents in Step 2/4 (no diff hunks will exist; use `hunks:0, +0/-0`).
       - Always run `git status --porcelain` in the **no-argument** flow after computing the diff, and include any **untracked** paths as **adds** in the review (same handling: `hunks:0, +0/-0`, include full contents). This keeps behavior consistent whether the tracked diff comes from `--staged` or `HEAD`.
         - If `git status --porcelain` includes directory-like entries (e.g. `?? dot_kube/`), expand them into concrete file paths using `Glob` scoped to that directory (e.g. `dot_kube/**`) and treat each matched file as an added file to `Read` and include in Step 2/4.
         - If `Glob` returns no files but the directory exists, report it as an untracked directory with unknown contents (coverage gap) rather than guessing.
   - Collect the list of changed files from the diff output
     - **Changed files extraction (minimum rule):**
       - Extract paths from lines like `diff --git a/<path> b/<path>` (prefer the `b/<path>` side)
       - Treat `/dev/null` as add/delete; if rename info exists, use the `rename to` path
     - **One-line change summary (standardize):**
       - Use a mechanical summary such as `hunks:<N>, +<A>/-<D>` per file
         - `N`: number of lines starting with `@@` in that file’s diff block
         - `A`: number of lines starting with `+` excluding the file header line `+++ b/<path>`
         - `D`: number of lines starting with `-` excluding the file header line `--- a/<path>`
         - For binary/submodule diffs that have no hunks, use `hunks:0, +0/-0`
   - **Empty diff:** If the diff output is empty (no changed files / no hunks), inform the user that there is nothing to review and **stop** — do not launch sub-agents.
     - For **base-branch reviews** (`git diff <branch>...HEAD`): this is intentionally a **committed-diff-only** view. If the user expects a review of their working tree (uncommitted changes), point them to `/code-review-agents` (no argument) or ask them to commit first and re-run.
     - Optionally, if the diff is empty but the situation looks suspicious, run `git status --porcelain` and explicitly tell the user what you found (or that it is clean) before stopping.
   - **If `gh` is unavailable (PR flow only):**
     - If `gh` is not installed, not authenticated, or the PR cannot be fetched, **stop** and tell the user to install/authenticate `gh` and re-run.

2. **Gather full context**
   - Before reading full contents, estimate whether you will exceed the ~50k Code Context limit (Step 4). If the diff is large, pre-group files into rounds first, then `Read` files per-round to avoid wasted context.
   - For each changed file, read the full file content using `Read` (not just the diff hunk)
   - Detect primary language(s) from file extensions
   - Optionally use `Glob` on relevant directories to understand the project structure (do not use shell `ls`)
   - **Do not launch any analysis agents until the Code Context block is complete** (Changed Files + Diff + File Contents for the files in the round). Partial contexts lead to low-signal reviews and forced retries.

3. **Read agent prompts**
   - Read [agent-prompts.md](agent-prompts.md) for per-agent prompt templates

4. **Build a shared code-context block**
   Assemble the following text to embed in every analysis agent's prompt:

   ```
   ## Changed Files
   <list of changed files with a one-line change summary each>

   ## Diff
   <full diff output>

   ## File Contents
   <full content of each changed file, labeled by path>
   ```

   If the total context (the full **Code Context** block above: Changed Files + Diff + File Contents) exceeds approximately 50 000 characters (counted as the constructed Code Context string length), split files into related groups and run multiple review rounds per group.
   - Counting rule (practical): treat the assembled Code Context as a single string and use its character length as the estimate. If an exact count is not available, approximate using file content sizes and keep each round comfortably below the limit.
   - Practical reminder: the **same Code Context is duplicated into 8 analysis prompts**. Staying under ~50k per-round keeps each specialist prompt reasonably sized; if you're close to the limit, split earlier (e.g., target ~35–40k) to avoid prompt-size issues.
   - **Grouping heuristic (in order):** directory/module → language → size (keep each group under ~50k)
   - **Merge rule:** concatenate specialist outputs across rounds and let the integration agent deduplicate; if any specialist is missing for any round, note it as a coverage gap.
   - **Diff in each round:** include only the `diff --git ...` blocks for files in that round (do not paste the full diff into every round)
   - **File contents in each round:** include only the full contents of files in that round

5. **Launch 8 analysis sub-agents in parallel**
   In a **single message**, issue 8 `Task` tool calls with these parameters:

   | Parameter | Value |
   |-----------|-------|
   | `subagent_type` | `"generalPurpose"` |
   | `readonly` | `true` |
   | `description` | Short label, e.g. `"Review: Security"` |
   | `prompt` | **Shared: Finding Format** + agent-specific section from agent-prompts.md **+** the code-context block (see [agent-prompts.md](agent-prompts.md) **How to construct prompts**) |

   All 8 calls **must** appear in the same assistant message so they execute in parallel.

6. **Collect results**
   Wait for all 8 agents to return their findings. If any agent **fails**, **times out**, or returns **empty or unusable** output: report that to the user; **retry** that agent once with the same prompt if appropriate; otherwise **proceed** with the available specialist outputs and instruct the integration agent to note the gap in **Overview** or a short **Coverage gap** subsection.

7. **Launch the integration sub-agent**
   Issue a single `Task` tool call:

   | Parameter | Value |
   |-----------|-------|
   | `subagent_type` | `"generalPurpose"` |
   | `readonly` | `true` |
   | `description` | `"Integrate review findings"` |
   | `prompt` | **Shared: Final Report Format** + Agent 9 section from agent-prompts.md **+** all available specialist outputs (see [agent-prompts.md](agent-prompts.md) **How to construct prompts**) |

8. **Present the final review**
   Display the integration agent's report to the user. Ask if they want to drill down into any area.

## Agent Roster

| # | Agent | Focus Area |
|---|-------|------------|
| 1 | Language Spec | Type safety, idioms, API misuse, deprecation |
| 2 | Refactoring & Patterns | Code smells, SOLID, Martin Fowler's refactoring catalog |
| 3 | DDD | Ubiquitous language, aggregates, value objects, bounded contexts |
| 4 | Clean Architecture | Layer boundaries, dependency rule, use case isolation |
| 5 | Security | OWASP Top 10, injection, auth, secrets, input validation |
| 6 | Performance | Complexity, N+1, memory, I/O, caching |
| 7 | TDD | t-wada's principles, test reliability, coverage, testability |
| 8 | Observability | Logging, metrics, tracing, error handling, operability |
| 9 | Integration | Synthesis, deduplication, prioritization, final report |

## Output formats (canonical)

Templates and severity tables are defined **only** in [agent-prompts.md](agent-prompts.md). Do not duplicate them in SKILL.md.

| What | Where in agent-prompts.md | Use |
|------|---------------------------|-----|
| Analysis findings | **Shared: Finding Format** (structure + severity table) | Copy verbatim into each analysis agent’s `Task` `prompt` per **How to construct prompts** |
| Integration report | **Shared: Final Report Format** | Copy verbatim into the integration agent’s `Task` `prompt` per **How to construct prompts** |

When changing formats, edit **agent-prompts.md** only.

## Notes

- **Output language**: Match the user's language preference (default: 日本語)
- **Large diffs**: Split into related file groups and run multiple rounds; merge before integration
- **Codebase exploration**: Analysis agents may also explore surrounding code with `Read` / `Grep` for broader context beyond the diff
- **Model choice**: Omit the `model` parameter (inherits from parent) for best quality; if you explicitly choose a faster model, use `model: "composer-2-fast"` consistently on all Task calls

## Restrictions

- Do not modify any code — this skill only produces review output
- Do not execute shell commands other than `gh pr diff`, `git diff`, `git log`, `git branch`, `git branch --list`, and `git status --porcelain`. For workspace inspection use the `Read`, `Glob`, and `Grep` tools only (no `ls`, `cat`, `find`, or similar shell utilities)
- Each sub-agent must stay within its designated expertise area
- Do not post review comments to GitHub (use `reply-pr-comment` for that)
