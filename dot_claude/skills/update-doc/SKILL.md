---
name: update-doc
description: Scan and update all markdown documents in the project to match the current source code.
disable-model-invocation: true
---

# Update Document
A skill to update documentation in the current project.

## Usage
```
/update-doc
```

## Steps
1. Check all markdown documents in the project using the `find . -type f -name '*.md'` command
  - If none are found, exit
1. For each document found, repeat the following:
  1. Check the document content using the `cat` command and create a summary
  1. Examine whether the document content contradicts the source code state
  1. If there are contradictions, notify the user of the content and correct the document
1. After all documents have been corrected, request a review from the user

## Restrictions
- Do not execute commands other than find and cat
- Do not edit files other than markdown
