#!/usr/bin/env python3
"""Run with: python3 scripts/tests/pi-opt.test.py"""

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
    scripts = home / "dotfiles/scripts"
    scripts.mkdir(parents=True)
    for name in ("pi-opt", "pi-optw"):
        shutil.copy2(repo / "scripts" / name, scripts / name)
    binary = home / "bin"
    binary.mkdir()
    fake_pi = binary / "pi"
    fake_pi.write_text("#!/usr/bin/env python3\nimport os,sys,json\n"
                       "print(json.dumps({'args':sys.argv[1:], 'env':dict(os.environ)}))\n")
    fake_pi.chmod(0o755)
    # Match the login shell: the routing wrapper precedes the managed Pi binary.
    # Going through scripts/pi clears OptChat's isolated agent config, exposing
    # personal model defaults, credentials, and package update notices in work.
    managed_pi = home / ".local/bin/pi"
    managed_pi.parent.mkdir(parents=True)
    shutil.copy2(fake_pi, managed_pi)
    for path in (".pi/agent", ".pi-work/agent"):
        profile = home / path
        profile.mkdir(parents=True)
        (profile / "auth.json").write_text('{"fixture":"not-a-real-token"}\n')
        (profile / "settings.json").write_text('{"packages":["normal-memory"]}\n')
    env = {**os.environ, "HOME": str(home), "PATH": f"{scripts}:{binary}:{os.environ['PATH']}",
           "PI_CODING_AGENT_DIR": "/inherited", "PI_CODING_AGENT_SESSION_DIR": "/inherited",
           "OPTCHAT_HOME": "/inherited", "PI_WORK_PROFILE": "1", "PI_SUBAGENT_PRESET": "work",
           "MEMORY_DIR": "/real-memory", "OPTCHAT_REFRESH_AT": "0", "PI_CACHE_RETENTION": "long",
           "ANTHROPIC_API_KEY": "inherited", "ANTHROPIC_AUTH_TOKEN": "inherited",
           "ANTHROPIC_OAUTH_TOKEN": "inherited"}

    def run(name, *args):
        result = subprocess.run([str(scripts / name), *args], env=env, text=True,
                                capture_output=True, check=True)
        return json.loads(result.stdout)

    for name, suffix, source, provider, summarizer in (
        ("pi-opt", ".pi-opt", ".pi/agent", "openai", "gpt-6-luna"),
        ("pi-optw", ".pi-opt-work", ".pi-work/agent", "anthropic", "claude-haiku-5-5"),
    ):
        result = run(name, "--model", "chosen/model", "prompt with spaces")
        root = home / suffix
        agent = root / "agent"
        memory = root / "memory/profiles/main"
        assert result["env"].get("PI_CODING_AGENT_DIR") == str(agent), (
            "OptChat must bypass scripts/pi, which clears its isolated model/auth/package config"
        )
        assert result["env"]["PI_CODING_AGENT_SESSION_DIR"] == str(root / "sessions")
        assert result["env"]["OPTCHAT_HOME"] == str(root / "memory")
        assert result["env"]["PI_CACHE_RETENTION"] == "long"
        for key in ("PI_WORK_PROFILE", "PI_SUBAGENT_PRESET", "MEMORY_DIR", "OPTCHAT_REFRESH_AT"):
            assert key not in result["env"]
        args = result["args"]
        for flag in ("--no-approve", "--no-extensions", "--no-context-files", "--no-skills",
                     "--no-prompt-templates", "--no-mcp"):
            assert flag in args
        assert args[args.index("--skill") + 1] == str(home / ".agents/skills")
        assert str(home / "dotfiles/pi/vendor/pi-optchat/src/index.ts") in args
        assert args[-3:] == ["--model", "chosen/model", "prompt with spaces"]
        assert (agent / "auth.json").is_symlink()
        assert (agent / "auth.json").resolve() == (home / source / "auth.json").resolve()
        settings = json.loads((agent / "settings.json").read_text())
        config = json.loads((memory / "config.json").read_text())
        assert settings["defaultProvider"] == provider
        assert not settings.get("packages")
        assert config["compactor"]["model"] == summarizer
        assert config["maxAgents"] == 4
        assert stat.S_IMODE((agent / "settings.json").stat().st_mode) == 0o600
        assert stat.S_IMODE((memory / "config.json").stat().st_mode) == 0o600
        if name == "pi-optw":
            assert str(home / "dotfiles/pi/work/guard.ts") in args
            assert settings["extensions"] == ["~/dotfiles/pi/work/guard.ts"]
            assert len(settings["skills"]) == 3
            for key in ("ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_OAUTH_TOKEN"):
                assert key not in result["env"]
        else:
            assert settings["extensions"] == []
        # Preserve later model/settings edits and the profile's learned instructions.
        (agent / "settings.json").write_text('{"custom":true}\n')
        (memory / "config.json").write_text('{"custom":true}\n')
        (memory / "AGENTS.md").write_text("User instructions\n")
        run(name, "--help")
        assert json.loads((agent / "settings.json").read_text()) == {"custom": True}
        assert json.loads((memory / "config.json").read_text()) == {"custom": True}
        assert (memory / "AGENTS.md").read_text() == "User instructions\n"
    for path in (".pi/agent", ".pi-work/agent"):
        assert json.loads((home / path / "settings.json").read_text()) == {"packages": ["normal-memory"]}
        assert json.loads((home / path / "auth.json").read_text()) == {"fixture": "not-a-real-token"}
    # Explicitly load the Herdr bridge and selected UI tools when installed.
    bridge = home / ".pi/agent/extensions/herdr-agent-state.ts"
    bridge.parent.mkdir(parents=True)
    bridge.touch()
    ui = home / "dotfiles/pi/agent/extensions/ask-user.ts"
    ui.parent.mkdir(parents=True)
    ui.touch()
    # An obsolete external overlay must not replace the versioned cache policy.
    overlay = home / ".local/share/herdr/pi-optchat-0.8.9"
    for file in ("src/index.ts", "herdr/extension.ts"):
        path = overlay / file
        path.parent.mkdir(parents=True, exist_ok=True)
        path.touch()
    personal = run("pi-opt", "--help")
    assert str(overlay / "src/index.ts") not in personal["args"]
    assert str(home / "dotfiles/pi/vendor/pi-optchat/src/index.ts") in personal["args"]
    assert str(home / "dotfiles/pi/vendor/pi-optchat/herdr/extension.ts") in personal["args"]
    assert str(ui) in personal["args"]
    assert personal["env"]["OPTCHAT_INSPECT_KEY"] == "f9"
    assert "npm:@plannotator/pi-extension@0.28.27" in personal["args"]
    work = run("pi-optw", "--help")
    assert str(home / "dotfiles/pi/vendor/pi-optchat/herdr/extension.ts") in work["args"]
    assert str(ui) not in work["args"]
    assert not any(arg.startswith("npm:@plannotator/pi-extension") for arg in work["args"])
    env["PI_CACHE_RETENTION"] = "short"
    assert run("pi-optw")["env"]["PI_CACHE_RETENTION"] == "short"
    env["PI_CACHE_RETENTION"] = "none"
    assert run("pi-optw")["env"]["PI_CACHE_RETENTION"] == "none"
    env["OPTCHAT_CACHE_DELEGATED"] = "long"
    assert run("pi-optw")["env"]["OPTCHAT_CACHE_DELEGATED"] == "long"
    env["OPTCHAT_CACHE_DELEGATED"] = "bogus"
    failure = subprocess.run([str(scripts / "pi-optw")], env=env, text=True, capture_output=True)
    assert failure.returncode == 1
    assert "OPTCHAT_CACHE_DELEGATED must be" in failure.stderr
    del env["OPTCHAT_CACHE_DELEGATED"]
    (home / ".pi/agent/auth.json").unlink()
    failure = subprocess.run([str(scripts / "pi-opt"), "--help"], env=env, text=True, capture_output=True)
    assert failure.returncode == 1
    assert "Missing credentials" in failure.stderr

print("pi-opt: isolated profiles, credential links, skills, work guard, defaults and preservation passed")
