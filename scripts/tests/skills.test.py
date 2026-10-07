#!/usr/bin/env python3
"""Run with: python3 scripts/tests/skills.test.py"""

import os
from pathlib import Path
import subprocess
import tempfile


repo = Path(__file__).resolve().parents[2]
script = (repo / "symlinks.sh").read_text()
# Exercise only the link helpers, not the rest of the machine setup script.
helpers = script[:script.index("# Create config directory")]
helpers += script[script.index("link_skills() {"):script.index("link_skills || exit 1")]


with tempfile.TemporaryDirectory() as directory:
    home = Path(directory)
    root = home / "dotfiles/skills"

    def skill(relative):
        folder = root / relative
        folder.mkdir(parents=True)
        (folder / "SKILL.md").write_text("---\nname: test\ndescription: test\n---\n")
        return folder

    upstream = skill("upstream/.agents/skills/downloaded")
    local = skill("local/custom")
    work = skill("work/work-only")
    managed = skill("local/nix-owned")
    independent = skill("local/independent")
    claude = home / ".claude/skills"
    claude.parent.mkdir()
    claude.symlink_to(root)
    shared = home / ".agents/skills"
    shared.mkdir(parents=True)
    nix_target = "/nix/store/test-home-manager-files/.agents/skills/nix-owned"
    (shared / managed.name).symlink_to(nix_target)
    (shared / independent.name).mkdir()

    def run(work_enabled=False):
        env = {**os.environ, "HOME": str(home),
               "DOTFILES_WORK_SKILLS": str(work_enabled).lower()}
        return subprocess.run(["bash", "-c", helpers + "\nlink_skills"],
                              env=env, text=True, capture_output=True)

    result = run()
    assert result.returncode == 0, result.stderr
    assert not claude.is_symlink(), "Old whole-directory link was not replaced"
    for profile in (".agents", ".claude", ".claude-personal", ".claude-work"):
        target = home / profile / "skills"
        assert (target / upstream.name).resolve() == upstream.resolve()
        assert (target / local.name).resolve() == local.resolve()
        assert not (target / work.name).exists()
    assert os.readlink(shared / managed.name) == nix_target
    assert not (shared / independent.name).is_symlink()

    result = run(work_enabled=True)
    assert result.returncode == 0, result.stderr
    for profile in (".agents", ".claude-work"):
        assert (home / profile / "skills" / work.name).resolve() == work.resolve()
    for profile in (".claude", ".claude-personal"):
        assert not (home / profile / "skills" / work.name).exists()

    result = run()
    assert result.returncode == 0, result.stderr
    assert not (shared / work.name).is_symlink()
    assert not (home / ".claude-work/skills" / work.name).is_symlink()
    assert os.readlink(shared / managed.name) == nix_target

    before = os.readlink(shared / local.name)
    skill("upstream/.agents/skills/custom")
    result = run(work_enabled=True)
    assert result.returncode != 0
    assert "duplicate skill folder name: custom" in result.stderr
    assert os.readlink(shared / local.name) == before

print("Skill links: ownership, work exposure, migration, and duplicate checks passed")
