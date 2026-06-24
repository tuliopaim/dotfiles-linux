---
name: create-pr-template
description: >
  Pull Request description template for creating clear, structured PR
  descriptions. Use when writing PR descriptions to ensure consistent
  formatting across the team.
---

# Pull Request Description Template

Use this template when creating PR descriptions:

````markdown
# Description

{Summary of what changed and why - 2-3 sentences explaining the problem and solution}

{If an issue tracker ticket exists: [TICKET-ID](link-to-ticket)}

## What's Changed
- Added: {New functionality with context}
- Updated: {Modified behavior with rationale}
- Fixed: {Bug fixes with issue description}
- Removed: {Deprecated code with reason}

## Files Changed

{List of all files with brief description of changes}

| File | Changes |
|------|---------|
| path/to/feature-file.ext | Brief description of change |
| path/to/component-file.ext | Brief description of change |

# Testing Instructions

Prerequisites:
- {Any setup required before testing}

Steps to Verify:
1. {First step to reproduce/verify}
2. {Second step}
3. {Third step}
4. {Expected result}

Run tests:
```bash
# Run the project's test, type-check, and lint commands
<test command>
<typecheck command>
<lint command>
```

# Setup Requirements

{List any of the following if applicable, otherwise state "No setup requirements."}

- Environment Variables: {New env vars needed in your environment config}
- Dependencies: {New packages added — run your package manager's install command}
- Routes: {New routes added to the application}

> No setup requirements.
````

## Template Variables

Replace these placeholders with actual values:

- {Summary of what changed and why} - Brief explanation of the change
- {New functionality with context} - What was added
- {Modified behavior with rationale} - What was changed and why
- {Bug fixes with issue description} - What was fixed
- {Deprecated code with reason} - What was removed
- {Any setup required before testing} - Prerequisites for testing
- {First step to reproduce/verify} - Testing step 1
- {Expected result} - What should happen
- {New env vars needed} - Environment variable requirements
- {New packages added} - Dependency additions
- {New routes added} - New application routes
