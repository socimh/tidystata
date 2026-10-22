"""Construct portable R commands while retaining protected Windows execution."""
import os
from pathlib import Path
import sys


def r_command(command, *, log_directory=None, timeout=900, platform=None, environ=None):
    platform = os.name if platform is None else platform
    environ = os.environ if environ is None else environ
    command = list(map(str, command))
    if platform != "nt":
        return command
    personal = Path("C:/Users/socimh/.codex/scripts/run_r_safe.py")
    default = personal if personal.is_file() else Path(__file__).with_name("run_r_safe.py")
    launcher = Path(environ.get("TIDYSTATA_R_LAUNCHER", str(default)))
    if not launcher.is_file():
        raise RuntimeError(
            "Protected Windows R launcher not found. Set TIDYSTATA_R_LAUNCHER "
            "to a verified run_r_safe.py; see CONTRIBUTING.md."
        )
    prefix = [sys.executable, str(launcher)]
    if log_directory is not None:
        prefix += ["--log-directory", str(log_directory)]
    return prefix + ["--timeout", str(timeout), "--", *command]


def r_environment(extra=None, libraries=()):
    env = os.environ.copy()
    if libraries:
        # R_LIBS prepends candidates without replacing R's normal user library,
        # including its default path when R_LIBS_USER was not explicitly set.
        paths = list(map(str, libraries))
        if env.get("R_LIBS"):
            paths.append(env["R_LIBS"])
        env["R_LIBS"] = os.pathsep.join(paths)
    if os.name == "nt":
        env.update(LC_ALL="C", LANG="C")
    env.update(extra or {})
    return env
