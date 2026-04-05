---
name: code-review-agents
description: >-
  Perform multi-perspective code review using 8 specialized analysis agents in
  parallel (language spec, refactoring, DDD, clean architecture, security,
  performance, TDD, observability) plus 1 integration agent that synthesizes
  all findings. Use when performing thorough code reviews, PR reviews, or
  when the user asks for a comprehensive code review.
disable-model-invocation: true
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
   - **Disambiguation:** If the argument is a bare integer (e.g. `42`), treat it as a **PR number**. Otherwise treat it as a **base branch name** for `git diff`. If the intent is ambiguous (e.g. a branch named like a number), ask the user before proceeding.
   - PR number → `gh pr diff <number>` and `gh pr view <number> --json baseRefName`
   - Branch name → `git diff <branch>...HEAD`
   - No argument → `git diff --staged` (fall back to `git diff HEAD`)
   - Collect the list of changed files from the diff output
   - **Empty diff:** If the diff output is empty (no changed files / no hunks), inform the user that there is nothing to review and **stop** — do not launch sub-agents

2. **Gather full context**
   - For each changed file, read the full file content using `Read` (not just the diff hunk)
   - Detect primary language(s) from file extensions
   - Optionally use `Glob` on relevant directories to understand the project structure (do not use shell `ls`)

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

   If the total context exceeds approximately 50 000 characters, split files into related groups and run multiple review rounds per group. Merge the per-round results before passing them to the integration agent.

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
- **Model choice**: Omit the `model` parameter (inherits from parent) for best quality; set `model: "fast"` on all Task calls for a quicker but less thorough review

## Restrictions

- Do not modify any code — this skill only produces review output
- Do not execute shell commands other than `gh pr diff`, `gh pr view`, `git diff`, `git log`, and `git branch`. For workspace inspection use the `Read`, `Glob`, and `Grep` tools only (no `ls`, `cat`, `find`, or similar shell utilities)
- Each sub-agent must stay within its designated expertise area
- Do not post review comments to GitHub (use `reply-pr-comment` for that)
