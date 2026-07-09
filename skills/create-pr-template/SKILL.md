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

{List of all files with brief description of changes. Prefer bullets for GitHub readability.}

- `path/to/feature-file.ext` — Brief description of change
- `path/to/component-file.ext` — Brief description of change

````

## Template Variables

Replace these placeholders with actual values:

- {Summary of what changed and why} - Brief explanation of the change
- {New functionality with context} - What was added
- {Modified behavior with rationale} - What was changed and why
- {Bug fixes with issue description} - What was fixed
- {Deprecated code with reason} - What was removed
- {Expected result} - What should happen
- {New env vars needed} - Environment variable requirements
- {New packages added} - Dependency additions
- {New routes added} - New application routes

## GitHub Rendering Rules

Optimize PR descriptions for GitHub Markdown rendering.

For `Files Changed`:

- Prefer a bullet list over a table when there are many files or long paths.
- Use a table only when each row has short content.
- If using a table:
  - Every row must have the exact same number of `|` columns.
  - Keep cells under ~60 characters.
  - Wrap file paths in backticks.
  - Use `<br>` only for short stacked details inside a cell.
  - Do not leave empty or missing cells.

Preferred format for many files:

```markdown
### Files Changed

- `src/path/to/file.ts` — brief change summary
- `src/path/to/another-file.ts` — brief change summary
```
