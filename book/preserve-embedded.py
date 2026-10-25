"""Quarto hooks: save and restore embedded sites without deleting any files."""
from pathlib import Path
import shutil
import subprocess
import sys

PRESERVED = ("CNAME", "cc-guide", "slides", "zh", "stata-to-r")


def restore_tracked(root):
    """Recover missing indexed assets when a fresh checkout has no local cache.

    Quarto cleans BEFORE pre-render scripts. Read Git's index as a fallback;
    never check out files, change the index, or overwrite an existing output.
    The outer render wrapper saves current, possibly uncommitted output first.
    """
    command = ["git", "-c", f"safe.directory={root.as_posix()}", "-C", str(root)]
    try:
        found = subprocess.run([*command, "ls-files", "-z", "--", *["docs/" + x for x in PRESERVED]],
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except FileNotFoundError:
        return
    if found.returncode:
        return
    for relative in found.stdout.decode("utf-8").split("\0"):
        if not relative:
            continue
        parts = Path(relative).parts
        target = (root / relative).resolve()
        if len(parts) < 2 or parts[0] != "docs" or parts[1] not in PRESERVED or root not in target.parents:
            raise ValueError("Indexed preservation path escaped the output roots.")
        if target.exists():
            continue
        content = subprocess.run([*command, "show", ":" + relative],
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if content.returncode:
            raise RuntimeError(f"Could not read indexed preservation asset: {relative}")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content.stdout)


def preserve(root, action):
    if action not in ("save", "restore"):
        raise ValueError("Expected save or restore.")
    root = Path(root).resolve()
    docs, cache = root / "docs", root / ".embedded-cache"
    source, destination = (docs, cache) if action == "save" else (cache, docs)
    for name in PRESERVED:
        item, target = source / name, destination / name
        if item.is_symlink() or target.is_symlink():
            raise ValueError("Embedded output must not be a symbolic link.")
        if item.is_dir():
            shutil.copytree(item, target, dirs_exist_ok=True)
        elif item.is_file():
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, target)
    if action == "restore":
        restore_tracked(root)


if __name__ == "__main__":
    preserve(Path(__file__).resolve().parent, sys.argv[1])
