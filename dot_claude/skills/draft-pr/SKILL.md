---
name: draft-pr
description: Create a draft pull request for the current branch with a structured PR body.
---

# Draft PR
A skill to create a Draft PR for the current branch.

## Usage
```
/draft-pr -adr [URL]
```

### Options
- `-adr [URL]`: Optional. A URL to an ADR (Architecture Decision Record) related to this PR

## Steps
1. Execute `gh pr list` command to check if a PR for the current branch already exists. If a PR already exists, inform the user and exit
1. If the current branch has not been pushed to the remote, push it using `git push -u origin $(git branch --show-current)`
1. Read @.github/PULL_REQUEST_TEMPLATE to understand the PR body structure
1. Identify the ticket ID from the current branch name (e.g., branch `feature/TSK-1234-some-description` contains ticket ID `TSK-1234`)
1. Compose the PR body at `/tmp/$(git branch --show-current).md` following the template structure:
   - Fill each section heading from the template with a concise one-line summary
   - In the Reference section, include:
     - A Notion ticket link derived from the ticket ID in the branch name (format: `https://www.notion.so/<org-name>/<ticket-id>`)
     - The ADR link if provided via `-adr` option, otherwise write "None"
   - Leave optional sections (e.g., Debug List, screenshots) with placeholder text or "N/A" for the user to fill in later
1. Create the draft PR using `gh pr create --draft --title "<concise title>" --body-file /tmp/$(git branch --show-current).md`

## Notes
- The PR title should be concise and descriptive of the changes
- Each section in the PR body should contain brief, clear summaries rather than lengthy explanations
- The Notion organization name for constructing the ticket URL should be inferred from the repository context or existing PR templates

## Restrictions
- Do not execute any commands other than `gh pr list`, `git push`, `git branch --show-current`, and `gh pr create`
