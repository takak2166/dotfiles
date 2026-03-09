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
1. Verify the PR is Open or Draft using `gh pr view [PR number]`. If not, inform the user and exit
1. Identify the target base branch and PR author using `gh pr view [PR number] --json baseRefName,author`
1. If a structured internal list of comments from `check-pr-comment` is already available in this conversation, reuse it. Otherwise, fetch **all** review comments using `gh api -X GET /repos/[owner]/[repo]/pulls/[pr_number]/comments --paginate`
   - Apply the same fetching rules as check-pr-comment (no filtering at API level, fetch all first)
   - If certificate or network errors occur, execute the same command from outside the sandbox
1. **Filter to actionable top-level comments only**
   - Exclude comments where `in_reply_to_id` is not `null` (these are replies, not top-level)
   - Include both human and bot comments (e.g., `github-actions[bot]`, `coderabbitai`). Bot comments can still be skipped later in the confirmation step if the user does not want to reply.
   - Exclude comments that already have a reply from the PR author (use `author.login` from `gh pr view` and compare with `user.login` in each reply within the same thread)
1. Collect the actual changes using `git log --oneline [base_branch]..HEAD` and `git diff [base_branch]...HEAD` to identify what was changed
   - Use the base branch identified in step 3
   - For each comment's `path`, check whether the relevant file was modified
1. For each actionable comment, generate a reply message:

   **Comment has a label prefix:**
   - `[q]` (question): Provide a direct answer based on the code and context
   - `[imo]` (opinion): State agreement or present a counterargument with reasoning
   - `[nits]` (nitpick): Acknowledge the fix (e.g., "Fixed, thanks!")

   **Comment requests a code change:**
   - If addressed → include what was changed and the commit short hash: `Fixed in <commit_hash>. <brief description of the change>`
   - If not addressed → explain why with a clear reason

   **Comment is praise or acknowledgment:**
   - By default, skip replying. Only when the user explicitly chooses to reply in the confirmation step, generate a brief thank-you message.

1. Present all generated replies to the user in a table format:

   ```
   | # | File | Comment (summary) | Reply (draft) |
   |---|------|-------------------|---------------|
   | 1 | path/to/file.ts | "Add null check" | "Fixed in abc1234. Added null guard." |
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

## Reply Format Guidelines
- Keep replies concise (1-3 sentences)
- When referencing a commit, use the 7-char short hash
- Do not include full diffs in replies
- Use the same language as the original comment (Japanese reply to Japanese comment, English reply to English comment)

## Restrictions
- Do not execute any commands other than `gh pr view`, `gh api`, `git log`, and `git diff`
- Do not post any reply without user confirmation
- Do not modify any code — this skill only posts replies
