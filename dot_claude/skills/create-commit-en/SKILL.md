---
name: create-commit-en
description: Generate an English commit message from staged changes with an appropriate prefix.
disable-model-invocation: true
---

# Create Commit In English 
A skill to create a commit in English from the current staging area.

## Usage
```
/create-commit-en
```

## Steps
1. Execute `git diff --staged` command to check the diff
  - If there's no diff, exit
1. Summarize the diff in one concise English sentence and select an appropriate prefix from feat/fix/chore/test/refactor/docs
1. Commit using `git commit -m "prefix: <commit message>"`
  - The commit message must start with a capital letter

## Restrictions
- Do not execute any commands other than `git diff --staged` and `git commit -m`
