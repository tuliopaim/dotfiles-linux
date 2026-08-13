---
description: Delegate focused, read-only code review to a high-reasoning model; call after a long or high-risk implementation
agent: review
---

$ARGUMENTS

Review the working tree, the given commit/range, or the named files plus the intended behavior. Run the actual diff and trace affected callers. Report findings in the compact handoff format: findings ordered by severity with evidence, impact, and smallest correct fix; validation gaps; and a one-sentence merge verdict.
