#!/usr/bin/env python3
"""Run with: python3 scripts/tests/piw.test.py"""

import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory() as directory:
    home = Path(directory)
    work = home / "dotfiles/pi/work"
    work.parent.mkdir(parents=True)
    shutil.copytree(repo / "pi/work", work)
    agents = home / "dotfiles/agents"
    agents.mkdir()
    (agents / "AGENTS.md").write_text("Shared instructions\n")
    binary = home / "bin"
    binary.mkdir()
    fake_pi = binary / "pi"
    fake_pi.write_text("#!/usr/bin/env python3\nimport os,sys,json\n"
                       "print(json.dumps({'args':sys.argv[1:], 'env':dict(os.environ)}))\n")
    fake_pi.chmod(0o755)
    env = {**os.environ, "HOME": str(home), "PATH": f"{binary}:{os.environ['PATH']}",
           "PI_CODING_AGENT_DIR": "/personal", "PI_CODING_AGENT_SESSION_DIR": "/personal/sessions",
           "PI_SUBAGENT_PRESET": "personal", "MEMORY_DIR": "/shared-memory",
           "ANTHROPIC_API_KEY": "inherited", "ANTHROPIC_AUTH_TOKEN": "inherited",
           "ANTHROPIC_OAUTH_TOKEN": "inherited"}

    def run(*args):
        result = subprocess.run(["bash", str(repo / "scripts/piw"), *args],
                                env=env, text=True, capture_output=True, check=True)
        return json.loads(result.stdout)

    result = run("--no-extensions", "--model", "anthropic/claude-sonnet-5-5", "prompt with spaces")
    profile = home / ".pi-work/agent"
    assert result["args"] == ["--extension", str(work / "guard.ts"), "--no-extensions",
                              "--model", "anthropic/claude-sonnet-5-5", "prompt with spaces"]
    assert result["env"]["PI_CODING_AGENT_DIR"] == str(profile)
    assert result["env"]["PI_CODING_AGENT_SESSION_DIR"] == str(profile / "sessions")
    assert result["env"]["PI_WORK_PROFILE"] == "1"
    assert result["env"]["PI_SUBAGENT_PRESET"] == "anthropic-work"
    assert result["env"]["PI_CACHE_RETENTION"] == "long"
    assert result["env"]["MEMORY_DIR"] == "/shared-memory"
    for name in ("ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_OAUTH_TOKEN"):
        assert name not in result["env"]
    for name in ("settings.json", "auth.json", "mcp.json"):
        assert not (profile / name).is_symlink()
        assert stat.S_IMODE((profile / name).stat().st_mode) == 0o600
        assert json.loads((profile / name).read_text()) == json.loads((work / name).read_text())
    assert (profile / "AGENTS.md").resolve() == (agents / "AGENTS.md").resolve()
    assert not (home / ".pi/agent").exists()
    (profile / "settings.json").write_text('{"custom":true}\n')
    (profile / "auth.json").write_text('{"custom":"credential"}\n')
    run("--help")
    assert json.loads((profile / "settings.json").read_text()) == {"custom": True}
    assert json.loads((profile / "auth.json").read_text()) == {"custom": "credential"}
    for command in ("auth", "mcp", "install", "remove", "uninstall", "update", "list", "config"):
        result = run(command, "--help")
        assert result["args"] == [command, "--help"]
        assert result["env"]["PI_CODING_AGENT_DIR"] == str(profile)

print("piw: separate profile, explicit guard, private files, argument forwarding, and preservation passed")
