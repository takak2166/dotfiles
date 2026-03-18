---
name: check-pr-comment
description: Review GitHub pull request comments and help the user triage them.
disable-model-invocation: true
---

# Check PR Comment
A skill to check comments on a specified PR number.

## Usage
```
/check-pr-comment [PR number]
```

## Steps
1. If no PR number is provided, prompt the user to enter it and exit
1. Get the repository name by running `gh repo view --json nameWithOwner -q .nameWithOwner` (returns `owner/repo`). Use this value for `[owner]` and `[repo]` in the API URL in the following steps
1. Verify the PR is Open or Draft using `gh pr view [PR number]`. If not, inform the user and exit
1. Fetch **all** review comments using `gh api -X GET /repos/[owner]/[repo]/pulls/[pr_number]/comments --paginate`
  - Do **not** filter by `path` or file name at the API level. Always fetch the complete set first.
  - If certificate errors or network errors occur, execute the same command from outside the sandbox
  - If review comments exist that are only available via review-specific endpoints, additionally check using `gh api -X GET /repos/[owner]/[repo]/pulls/[pr_number]/reviews/{review_number}/comments` as needed
1. Convert the JSON response into a **structured internal list** with **one row per comment**
  - For each comment, extract at least the following fields:
    - `id`
    - `path`
    - `original_line` or `line`
    - `user.login`
    - `body`
    - `in_reply_to_id` (for detecting threads)
  - You may pipe the raw output through helpers such as `jq` to make it easier to read, but the internal representation must still contain **all** comments
1. Group and summarize comments **systematically**
  - First group by `path` (file)
  - Within each file, further group comments by thread using `original_position` / `in_reply_to_id` (i.e., treat a top-level comment and its replies as one thread)
  - When summarizing, you **must explicitly touch every top-level comment** (where `in_reply_to_id` is `null`) at least once
    - For each top-level comment, produce a 1–2 line note covering:
      - What is being pointed out (e.g., validation, performance, tests, naming, architecture)
      - Whether you recommend “will address” or “will not address”, and the short reason
  - Clearly distinguish **bot vs human** comments:
    - If `user.login` indicates a bot (e.g., `github-actions[bot]`, `coderabbitai`), mark them as “lower priority” compared to human reviewers
    - However, do **not** ignore bot comments; they must still appear in the grouped summary
1. Perform a **coverage check** to prevent missed comments
  - Collect the set of all `id` values from the `gh api` results
  - Collect the set of `id`s that are covered in your internal summary / triage representation`
  - Compare the two sets:
    - If there are comment `id`s that are not yet covered in the summary, inspect each one
    - Decide whether it is intentionally skipped as “very minor” or was previously overlooked
    - If it was overlooked, add at least one line of summary so that **every comment `id` is either summarized or intentionally justified as skipped**
1. Validate the appropriateness of the comments
1. Score each comment's difficulty and importance on a 3-point scale, then ask the user whether to address them

## Notes
- When validating comment appropriateness, check if they align with project guidelines (@.claude/**/*.md) and maintain consistency with existing similar implementations
  - Also check if the issues mentioned are specific to older versions
- For long JSON / diff outputs:
  - Do **not** arbitrarily skip parts of the diff just because `diff_hunk` or `body` is long
  - Conceptually **slice the JSON per comment** and process it comment by comment
  - For each comment, it is acceptable to focus on:
    - The first few lines of the comment body, and
    - The main intent (suggestion / question / praise),
    rather than reading every line of a large diff
- Comments from `github-actions[bot]`, `coderabbitai`, or other bots are AI-generated reviews, so assign them lower importance than comments from human reviewers, but always keep them in the summary

## Restrictions
- Do not execute any commands other than `gh repo view`, `gh pr view`, and `gh api -X GET`
