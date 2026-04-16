---
name: reply-pr-comment
description: Reply to GitHub pull request review comments with resolution results. Posts replies describing code changes, answers to questions, or reasons for not addressing. Use after check-pr-comment triage when the user wants to reply to PR comments.
disable-model-invocation: true
---

# Reply PR Comment
A skill to reply to review comments on a specified PR with resolution results, assuming `check-pr-comment` has already been used to triage the comments in the same conversation.

## Usage
```
/reply-pr-comment [PR number]
```

## Steps
This skill assumes that the **current checkout branch** is the **head branch of the target PR**. If it is not, the mapping between comments and local diffs may be incorrect.

1. If no PR number is provided, prompt the user to enter it and exit
1. Get the repository name by running `gh repo view --json nameWithOwner -q .nameWithOwner` (returns `owner/repo`). Use this value for `[owner]` and `[repo]` in the API URLs in the following steps
1. Verify the PR is Open or Draft using `gh pr view [PR number]`. If not, inform the user and exit
1. Identify the target base branch, PR author, and PR head branch name using `gh pr view [PR number] --json baseRefName,author,headRefName`
1. **Verify the local branch matches the PR head.** Run `git branch --show-current`. If the output is empty (e.g. detached HEAD) or does not match `headRefName` from the previous step, inform the user (show both values) and exit
1. If a structured internal list of comments from `check-pr-comment` is already available in this conversation, reuse it. Otherwise, fetch **all** review comments using `gh api -X GET /repos/[owner]/[repo]/pulls/[pr_number]/comments --paginate`
   - Apply the same fetching rules as check-pr-comment (no filtering at API level, fetch all first)
   - If certificate or network errors occur, execute the same command from outside the sandbox
1. **Filter to actionable top-level comments only**
   - Exclude comments where `in_reply_to_id` is not `null` (these are replies, not top-level)
   - Include both human and bot comments (e.g., `github-actions[bot]`, `coderabbitai`). Bot comments can still be skipped later in the confirmation step if the user does not want to reply.
   - Exclude comments that already have a reply from the PR author (use `author.login` from `gh pr view` and compare with `user.login` in each reply within the same thread)
1. Collect the actual changes using `git log --oneline [base_branch]..HEAD` and `git diff [base_branch]...HEAD` to identify what was changed
   - Use the base branch identified in step 4
   - For each comment's `path`, check whether the relevant file was modified
1. For each actionable comment, generate a reply message per **Reply types and templates** (below)
1. Present all generated replies to the user in a table format:

   ```
   | # | File | Comment (summary) | Reply (draft) |
   |---|------|-------------------|---------------|
   | 1 | path/to/fetch.py | "try/except が効かない" | (2段落: 問題の整理 + `abc1234` での修正とテスト) |
   | 2 | path/to/api.ts | "[q] Why use X?" | "X was chosen because..." |
   ```

   Ask the user to confirm, edit, or skip individual replies

1. Post approved replies using `gh api -X POST /repos/[owner]/[repo]/pulls/[pr_number]/comments` with:
   ```json
   {
     "body": "<reply message>",
     "in_reply_to": <comment_id>
   }
   ```
1. Report a summary of posted replies (count, any failures)

## Reply types and templates

Use this section as the **single place** to decide **which** reply shape applies. **Reply structure (not addressed)** and **Reply structure (addressed change)** below define **how** to write that shape (paragraph layout only).

- **Label prefix on the comment:**
  - `[q]` (question): Direct answer from code and context
  - `[imo]` (opinion): Agreement or counterargument with reasoning
  - `[nits]` (nitpick): Thanks for the fix; GitHub emoji in the first paragraph when it fits (e.g. `:pray:`)
- **Suggestion / code change (no such prefix):**
  - If **addressed** (including a **partial** fix: some code for this point landed on the branch): use **Reply structure (addressed change)**. Match the original comment’s language.
  - If **not addressed**: use **Reply structure (not addressed)** (clear reason; optional follow-up). Do not use a commit hash or imply a fix landed when it did not.
- **Praise or acknowledgment:** By default, skip replying. Only when the user explicitly chooses to reply in the confirmation step, generate a brief thank-you message.
- **Very short comment (one line, minor nit, or quick question):** Keep the reply proportionally short; do not stretch to the full **Reply structure (addressed change)** layout when the thread does not need that depth.

**Addressed vs. not — commit hash and Resolution**

| Situation | Commit hash | Resolution paragraph (addressed only) |
|-----------|-------------|----------------------------------------|
| Addressed | Required: 7-char hash at start of **Resolution** | **No emoji** |
| Not addressed / deferred | Omit; do not fake a hash | *N/A — there is no Resolution paragraph in this template* |
| `[q]` / `[imo]` / `[nits]` / praise (when replying) | Only if you actually fixed code (**addressed**); otherwise omit | Use **addressed** rules only when posting an **addressed** reply |

- **Not addressed / deferred** means out of scope, disagree with the premise, revisit when evidence appears, etc. Do **not** apply the two-paragraph **addressed** template in those cases. The Resolution “no emoji” rule applies **only** to **addressed** replies.

**Emoji (all reply shapes)**

**Do not stack** multiple emoji **back-to-back at the end of one sentence** (e.g. avoid `:pray: :+1:` on the same line); a **single** trailing emoji in a sentence is fine.

## Reply structure (not addressed)

Use when you **choose not to implement** the suggestion (or defer it), not when a fix is already on the branch.

- **Length:** Often thanks + one or two short rationale paragraphs; match the comment language.
- **Emoji:** Natural where it fits; follow **Emoji (all reply shapes)** above. Not governed by the **addressed** Acknowledgment/Resolution split.
- **Do not** open with or cite a commit hash to stand in for a fix that did not happen. If code **did** land, switch to **Reply structure (addressed change)**.

## Reply structure (addressed change)

When the reviewer’s point was valid and you fixed it in code, prefer **two short paragraphs** (not a single English one-liner):

1. **Acknowledgment:** Agree with the point; briefly restate the issue or root cause (e.g. why the bug happened). **Use GitHub emoji liberally** (`:name:` syntax) **only in this paragraph**—e.g. `:pray:` for thanks / お願い, `:bow:` for 失礼しました, `:sweat:` when the bug was subtle or embarrassing; `:+1:` / `:ok_person:` for agreement, `:eyes:` for caution. Match the comment language; emoji are language-agnostic. Ending with **`!`** is fine when it matches the tone. Aim for **several emoji** when it reads naturally (not one token per sentence; avoid looking like spam). Follow **Emoji (all reply shapes)** for stacking.
2. **Resolution:** **Do not use emoji** in this paragraph. Start with the **7-char commit short hash** (e.g. 4e95eb0) inline at the start of this paragraph and describe what you added/changed (function names, behavior). Mention **regression tests** and paths (e.g. `tests/test_fetch_cmd.py`) when added or updated.

**Constraints (addressed changes):** Do not paste full diffs; summarize only. Use the same language as the original comment (Japanese reply to Japanese comment, English reply to English comment). Keep each paragraph focused (avoid rambling).

For **short** review comments, prefer a **short** reply (see example below); the two-paragraph + commit-hash pattern is for substantive fixes, not every thread.

## Example (Japanese, addressed change)
```
ご指摘の通り、ジェネレータの遅延評価で try/except が効かず、Message Fetch Error アラートが送られなくなっていました :pray:
4e95eb0 で _slack_fetch_iter_with_alert を追加し、yield from 内で遅延イテレーション中の例外を捕捉して「Message Fetch Error」アラートを送るようにしました。tests/test_fetch_cmd.py で回帰テストも追加しました。
```

## Example (Japanese, brief reply to a short comment)
When the review is a small style or preference point and you are keeping the current approach (or the exchange does not need commit hashes and test paths), a short acknowledgment plus one paragraph of rationale is appropriate.

```
コメントありがとうございます！
パフォーマンスは実質差がなく、コメントを各行に付けられたほうがレビューや保守時の可読性が上がるかと思ったので、現状の形で統一しようと思います :pray:
```

## Example (Japanese, deferred / not addressing now)
Concrete example of **Reply structure (not addressed)**. Give a clear reason (repo conventions, tool behavior, cost/benefit) and state what would trigger a follow-up (e.g. a reproducible build or runtime issue). Thanks first, then rationale.

```
コメントありがとうございます！
src 直下にも __init__.py がなく、src/bot など 多くのサブパッケージも __init__.py なしで運用されているため、「全サブパッケージに __init__.py がある」という前提はこのリポジトリとは一致ないかと思いました :pray:
poetry の packages = [{include = "src"}] でも通常は配下モジュールが取り込まれる想定のため、poetry build の成果物で src.mattermost が欠ける事象が出たら対応しようかと思います :pray:
```

## Restrictions
- Do not execute any commands other than `gh repo view`, `gh pr view`, `gh api`, `git branch --show-current`, `git log`, and `git diff`
- Do not post any reply without user confirmation
- Do not modify any code — this skill only posts replies
