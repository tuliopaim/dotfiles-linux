---
description: Process code review comments left in .review/comments.json by the Neovim review plugin
---

Use the review-comments skill. $ARGUMENTS

Read `<repo>/.review/comments.json` and walk through every entry where `resolved` is `false`. For each unresolved comment, implement the requested fix, discuss if ambiguous, or mark it obsolete if the code has changed. Set `resolved` to `true` after addressing.
