"""Run hosted Windows checks through the portable protected launcher.

Dependency setup remains managed by r-lib/actions. All R processes started here,
including R CMD check descendants, inherit the protected Windows environment.
"""
import json
import os
from pathlib import Path
import subprocess
import sys

from r_process import r_command, r_environment

ROOT = Path(__file__).resolve().parents[2]
DESTINATION = ROOT / ".opencode/results/compatibility-windows"


def main():
    DESTINATION.mkdir(parents=True, exist_ok=True)
    receipt = {name: os.environ.get(name) for name in (
        "GITHUB_SHA", "GITHUB_REF", "GITHUB_RUN_ID", "GITHUB_RUN_ATTEMPT",
        "RUNNER_OS", "RUNNER_ARCH",
    )}
    receipt["git_commit"] = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True, encoding="utf-8").strip()
    receipt["git_status"] = subprocess.check_output(
        ["git", "status", "--porcelain", "--untracked-files=no"],
        cwd=ROOT, text=True, encoding="utf-8")
    (DESTINATION / "source.json").write_text(
        json.dumps(receipt, indent=2), encoding="utf-8")
    environment = r_environment({
        "STATART_R_LAUNCHER": str(ROOT / ".opencode/workflows/run_r_safe.py"),
        "STATART_CI_RESULTS": str(DESTINATION),
    })
    expression = '''
destination <- Sys.getenv("STATART_CI_RESULTS")
cat(R.version.string, "\\nLibraries:", .libPaths(), "\\n")
result <- rcmdcheck::rcmdcheck(
  args = c("--no-manual", "--as-cran"),
  error_on = "never", check_dir = file.path(destination, "check"))
saveRDS(result, file.path(destination, "check-result.rds"))
stopifnot(length(result$status) == 1L, !is.na(result$status),
          result$status == 0, identical(result$timeout, FALSE))
writeLines(as.character(result$status), file.path(destination, "native-status.txt"))
'''
    command = r_command(["Rscript", "-e", expression],
                        log_directory=DESTINATION / "launcher", timeout=2400,
                        environ=environment)
    result = subprocess.run(command, cwd=ROOT, env=environment, check=False)
    if result.returncode:
        return result.returncode
    native_status = (DESTINATION / "native-status.txt").read_text(encoding="utf-8").strip()
    parser = ROOT / ".opencode/workflows/parse_check_result.R"
    command = r_command([
        "Rscript", str(parser),
        str(DESTINATION / "check/statart.Rcheck/00check.log"), native_status,
        str(DESTINATION / "check-result.json"),
    ], log_directory=DESTINATION / "launcher", environ=environment)
    return subprocess.run(command, cwd=ROOT, env=environment, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
