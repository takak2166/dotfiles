---
name: plan
description: Create a phased implementation plan based on an ADR with review and branching rules.
disable-model-invocation: true
---

# Plan
A skill to create an implementation plan based on an ADR.

## Usage
```
/plan -adr [ADR URL]
```

## Steps
1. Review the ADR
  - Check the differences between ADR content and current implementation
  - Summarize what you understand in bullet points
1. The implementation plan must include the development process described below
1. Divide the necessary implementation into phases according to the following rules:
  - Each phase must begin with a step to "confirm the development process"
  - The number of added/deleted/updated lines of code per phase should not exceed 500 lines (excluding blank lines and comments)
  - Each phase should be independently testable and verifiable
    - Include verification procedures and expected results
  - Specify what to implement and which files to create/modify in each phase

### Development Process
- Create a new branch from the latest main branch using `git switch -c` before implementing each phase
- After completing each phase implementation, request a review from the user via chat
- If modifications are needed after review, make corrections and request review again
- Do not proceed to the next phase without receiving approval comments from the user
- When proceeding to the next phase, stage the diff with `git add` and execute the steps in @create-commit-en.md
