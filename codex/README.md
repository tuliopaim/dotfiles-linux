# Commit agent

`commit.toml` defines the Luna commit agent. Home Manager links it into
`~/.codex/commit.toml`.

Codex 0.162.1 also needs this registration in the machine-local
`~/.codex/config.toml`, which stays a real file so Codex can update it:

```toml
[agents.commit]
description = "Create scoped commits only when the user explicitly requests commits. Follow the commit-work skill and leave unrelated changes untouched."
config_file = "/Users/tuliopaim/dotfiles/codex/commit.toml"
```

Use an absolute path to the real file, not the Home Manager symlink. Adjust the
home directory on other machines. The agent file uses the registered-role
format supported by the installed client.

Ask the main agent to "commit this work" or "use the commit agent". It supplies
the checkout, scope, authorization, and validation results. The commit agent
reads `~/.agents/skills/commit-work/SKILL.md` and never pushes unless asked.

In T3, native agent availability depends on its backend. If T3 exposes only its
orchestration tools, `~/dotfiles/agents/T3.md` supplies the provider-specific
cheap-model routing instead.
