"""Launch R/Quarto with a repaired Windows environment and no crash dialogs.

Usage: python run_r_safe.py [--log-directory DIR] [--timeout SECONDS] -- Rscript [args...]
Preserves the working directory, R startup files, libraries, and argument boundaries.
"""
import argparse
import ctypes
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log-directory", type=Path,
                        default=Path(tempfile.gettempdir()) / "CodexRLogs")
    parser.add_argument("--timeout", type=float)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command
    if command[:1] == ["--"]:
        command = command[1:]
    if not command:
        parser.error("a command is required after --")
    if args.timeout is not None and args.timeout <= 0:
        parser.error("timeout must be positive")
    command[0] = shutil.which(command[0]) or command[0]
    args.log_directory.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    stem = args.log_directory / (stamp + "-" + uuid.uuid4().hex[:8])
    out_path, err_path = Path(str(stem)+".out.log"), Path(str(stem)+".err.log")
    status = dict(command=command, cwd=str(Path.cwd()), started=stamp, timeout=False)
    env = os.environ.copy()
    flags = 0
    kernel, old_mode = None, None
    print("R launcher logs: " + str(stem), file=sys.stderr, flush=True)
    try:
        if os.name == "nt":
            kernel = ctypes.WinDLL("kernel32", use_last_error=True)
            kernel.GetErrorMode.restype = ctypes.c_uint
            kernel.SetErrorMode.argtypes = [ctypes.c_uint]
            kernel.SetErrorMode.restype = ctypes.c_uint
            old_mode = kernel.GetErrorMode()
            kernel.SetErrorMode(old_mode | 0x8003)
            if kernel.GetErrorMode() & 2 == 0:
                raise RuntimeError("Could not enable crash-dialog suppression")
            # Native Windows SYSTEM_INFO starts with a WORD architecture field.
            if not env.get("PROCESSOR_ARCHITECTURE"):
                info = ctypes.create_string_buffer(64)
                kernel.GetNativeSystemInfo.argtypes = [ctypes.c_void_p]
                kernel.GetNativeSystemInfo.restype = None
                kernel.GetNativeSystemInfo(info)
                architecture = ctypes.c_ushort.from_buffer(info).value
                names = {0: "x86", 5: "ARM", 9: "AMD64", 12: "ARM64"}
                if architecture not in names:
                    raise RuntimeError("Unknown Windows architecture: " + str(architecture))
                env["PROCESSOR_ARCHITECTURE"] = names[architecture]
            flags = subprocess.CREATE_NO_WINDOW
        status["processor_architecture"] = env.get("PROCESSOR_ARCHITECTURE")
        with out_path.open("wb") as stdout, err_path.open("wb") as stderr:
            try:
                result = subprocess.run(command, env=env, stdin=subprocess.DEVNULL,
                                        stdout=stdout, stderr=stderr, creationflags=flags,
                                        timeout=args.timeout, check=False)
                status["exit_code"] = result.returncode
            except subprocess.TimeoutExpired:
                status.update(exit_code=124, timeout=True)
            except OSError as exc:
                status.update(exit_code=127, error=str(exc))
                stderr.write((str(exc)+"\n").encode("utf-8"))
    except Exception as exc:
        status.update(exit_code=1, error=str(exc))
    finally:
        if kernel is not None and old_mode is not None:
            kernel.SetErrorMode(old_mode)
    status["exit_hex"] = f"0x{status['exit_code'] & 0xffffffff:08X}"
    Path(str(stem)+".status.json").write_text(
        json.dumps(status, ensure_ascii=False, indent=2), encoding="utf-8")
    for path, stream in ((out_path, sys.stdout), (err_path, sys.stderr)):
        if path.exists():
            with path.open("rb") as source:
                shutil.copyfileobj(source, stream.buffer)
            stream.flush()
    print(f"R launcher exit: {status['exit_hex']}; status: {stem}.status.json", file=sys.stderr)
    if "error" in status:
        print(status["error"], file=sys.stderr)
    code = status["exit_code"]
    return code if 0 <= code <= 255 else 1


if __name__ == "__main__":
    raise SystemExit(main())
