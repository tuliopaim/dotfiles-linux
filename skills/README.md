# Skills

Keep all skill sources here:

- `upstream/.agents/skills/`: third-party skills managed by the Vercel skills CLI.
- `upstream/skills-lock.json`: the CLI's source and content-hash records.
- `local/`: skills you maintain or deliberately fork.
- `work/`: work-only skills.

## Add and update

Run the CLI from `upstream`. It installs relative to the current directory.
`--agent codex` selects its standard `.agents/skills/` destination; it does not
limit which agents can use the skills. Do not use `--global`.

```sh
cd ~/dotfiles/skills/upstream
npx skills@latest add mattpocock/skills --agent codex
npx skills@latest list
npx skills@latest update --project
```

Review changes with `git diff -- skills` and `git status --short -- skills` from
the dotfiles root. Upstream skills are not automatically updated at startup.
Do not edit them directly. Copy a skill into `local/` to maintain your own
version. Use a distinct folder and frontmatter name if keeping both versions.

## Agent links

Nix links individual skill folders into `~/.agents/skills/` and the Claude
profiles. Codex, Pi, and OpenCode discover the shared directory natively.
Duplicate folder names fail configuration instead of silently overriding files.

Work skills go only to the work Claude profile and the shared directory when
`dotfiles.workSkills.enable` is enabled. The shared directory is machine-wide,
so work skills are available to all agents on that machine, not profile-isolated.

For non-Nix machines, `symlinks.sh` creates the same per-skill links. Opt into
work skills with `DOTFILES_WORK_SKILLS=true bash ~/dotfiles/symlinks.sh`.
Nix-owned and independently installed skills are left alone.

Existing linked files reflect edits immediately. New or removed skill folders
require applying the Nix configuration. Git-based flakes require tracking the
new files first. Mark new paths as intent-to-add without staging their contents,
then use your normal rebuild command:

```sh
cd ~/dotfiles
git add -N -- skills
fswitch
```

Alternatively, to apply untracked changes without changing the Git index:

```sh
sudo darwin-rebuild switch --flake "path:$HOME/dotfiles?dir=nix#macbook"
```

Replace `macbook` with the host name where needed. Keep per-skill links rather
than linking a whole Claude skills directory, because Claude writes its own
`synced` skills there.

## Exceptions

Pi package skills, including Ponytail, remain package-managed. Independent home
installs such as Plannotator, agent-browser, and find-skills are unchanged.
The migration preserved all existing skill contents. The customized `unslop`
skill is now a local fork of `cursor/plugins`, removed from the upstream lock
file so CLI updates cannot overwrite it.
