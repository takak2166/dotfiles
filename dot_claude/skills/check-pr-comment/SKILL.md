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
1. Verify the PR is Open or Draft using `gh pr view [PR number]`. If not, inform the user and exit
1. Check all comments using `gh api -X GET /repos/[owner]/[repo]/pulls/[pr_number]/comments --paginate`
  - If certificate errors or network errors occur, execute from outside the sandbox
  - If review comments exist, additionally check using `gh api -X GET /repos/[owner]/[repo]/pulls/[pr_number]/reviews/{review_number}/comments`
  - If there are many comments, pipe the output through `jq -r '.[] | "=== \(.path):\(.line) ===\n\(.body)\n"'` to make it more readable
1. Validate the appropriateness of the comments
1. Score each comment's difficulty and importance on a 3-point scale, then ask the user whether to address them

## Notes
- When validating comment appropriateness, check if they align with project guidelines (@.claude/**/*.md) and maintain consistency with existing similar implementations
  - Also check if the issues mentioned are specific to older versions
- Comments from github-actions or coderabbitai are AI-generated reviews, so assign them lower importance than comments from human reviewers

## Restrictions
- Do not execute any commands other than `gh pr view` and `gh api -X GET`
