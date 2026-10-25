"""Stage and verify a personal-site integration before applying local changes."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import uuid

HERE = Path(__file__).resolve().parent
SOURCE_FILES = ("_quarto.yml", "books.qmd", "software.qmd", ".gitignore")
OPTIONAL_SOURCES = ("render-site.sh", "zh/_quarto.yml", "zh/books.qmd", "zh/software.qmd")
EXCLUDED = {".git", ".quarto", ".claude", ".superpowers", ".Rproj.user", ".embedded-cache",
            "private-backups", ".Rhistory", ".RData", "bash.exe.stackdump"}
BOOK_PATH = "stata-to-r/index.html"


def replace_once(text, before, after):
    if text.count(before) != 1:
        raise ValueError(f"Expected one source marker: {before!r}")
    return text.replace(before, after, 1)


def add_card(text, card):
    marker = "<!-- stata-to-r-reference -->"
    if marker in text:
        return text
    if not text.startswith("---\n") or "\n---\n" not in text[4:]:
        raise ValueError("Expected Quarto YAML front matter.")
    end = text.index("\n---\n", 4) + 5
    return text[:end] + "\n" + marker + "\n" + card + "\n" + text[end:]


def patch_sources(source):
    result = dict(source)
    config = result["_quarto.yml"]
    if "_preserve-embedded.py restore" not in config:
        if "  pre-render:" in config:
            raise ValueError("Existing pre-render hook needs explicit integration.")
        config = replace_once(config, "  post-render: bash _restore-preserved.sh",
                              "  pre-render: python _preserve-embedded.py save\n"
                              "  post-render: python _preserve-embedded.py restore")
    if BOOK_PATH not in config:
        marker = "            href: https://www.socimh.com/cc-guide/"
        config = replace_once(config, marker, marker + '\n          - text: "Stata → R Reference / Stata 转 R"\n'
                              f"            href: {BOOK_PATH}")
    if '"!.embedded-cache/**"' not in config:
        config = replace_once(config, '    - "!private-backups/**"',
                              '    - "!private-backups/**"\n    - "!.embedded-cache/**"')
    result["_quarto.yml"] = config
    card = ('::: {.entry-card}\n'
            '[Stata to R Reference / Stata 转 R 参考手册](stata-to-r/index.html)\n\n'
            '*A searchable bilingual reference for Stata users working in R*\n\n'
            'Browse Stata–R comparisons by subject, command or R package. English and\n'
            'Chinese editions share the same examples, with a language switch on each\n'
            'chapter. The reference accompanies [tidystata](https://socimh.github.io/tidystata/)\n'
            'and is separate from the introductory textbook.\n:::\n')
    result["books.qmd"] = add_card(result["books.qmd"], card)
    result["software.qmd"] = add_card(result["software.qmd"], card)
    if "/.embedded-cache/" not in result[".gitignore"]:
        result[".gitignore"] = result[".gitignore"].rstrip() + "\n\n# Local preservation cache for embedded books and slides.\n/.embedded-cache/\n"
    result["_preserve-embedded.py"] = (HERE / "preserve-embedded.py").read_text(encoding="utf-8")
    if "render-site.sh" in result and "python _preserve-embedded.py save" not in result["render-site.sh"]:
        script = result["render-site.sh"]
        script = replace_once(script, 'cd "$(dirname "$0")"',
                              'cd "$(dirname "$0")"\n\n# Save current embedded output before Quarto can clean it.\npython _preserve-embedded.py save')
        script = replace_once(script, "\nquarto render\n", "\nquarto render --no-clean\n")
        script = script.replace("(cd zh && quarto render)", "(cd zh && quarto render --no-clean)")
        result["render-site.sh"] = script
    if "zh/_quarto.yml" in result and "../stata-to-r/zh/index.html" not in result["zh/_quarto.yml"]:
        marker = "            href: https://www.socimh.com/cc-guide/"
        result["zh/_quarto.yml"] = replace_once(result["zh/_quarto.yml"], marker,
            marker + '\n          - text: "Stata 转 R 参考手册"\n            href: ../stata-to-r/zh/index.html')
    chinese_card = ('::: {.entry-card}\n[Stata 转 R 参考手册](../stata-to-r/zh/index.html)\n\n'
                    '按主题、Stata 命令或 R 包查阅代码对照。中英文版本使用相同示例，每章均可切换语言。'
                    '本手册配合 [tidystata](https://socimh.github.io/tidystata/) 使用，与入门教材分别维护。\n:::\n')
    for name in ("zh/books.qmd", "zh/software.qmd"):
        if name in result:
            result[name] = add_card(result[name], chinese_card)
    return result


def fingerprint(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None


def embedded_files(site):
    files = {}
    for name in ("CNAME", "cc-guide", "slides", "zh", "stata-to-r"):
        item = site / "docs" / name
        paths = item.rglob("*") if item.is_dir() else [item]
        for path in paths:
            if path.is_file():
                files[path.relative_to(site).as_posix()] = fingerprint(path)
    return files


def snapshot(site):
    return {p.relative_to(site).as_posix(): fingerprint(p) for p in site.rglob("*")
            if p.is_file() and not any(x in EXCLUDED for x in p.relative_to(site).parts)}


def export_updates(staging, rendered_site, updates):
    """Put checked apply inputs in the shared workspace, outside private temp ACLs."""
    destination = Path(staging) / ("apply-source-" + uuid.uuid4().hex[:8])
    destination.mkdir()
    for entry in updates:
        source, target = rendered_site / entry["path"], destination / entry["path"]
        if fingerprint(source) != entry["after"]:
            raise ValueError(f"Prepared source changed: {entry['path']}")
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        if fingerprint(target) != entry["after"]:
            raise ValueError(f"Apply-source copy differs: {entry['path']}")
    return destination


def prepare(personal_site, book_site, staging, run, protected, environment):
    personal_site, book_site, staging = Path(personal_site).resolve(), Path(book_site).resolve(), Path(staging).resolve()
    if staging.exists():
        raise ValueError("Choose a fresh personal-site staging directory.")
    if personal_site == staging or personal_site in staging.parents:
        raise ValueError("Stage outside the personal-site checkout.")
    if not (book_site / "zh/index.html").is_file():
        raise ValueError("Both rendered book editions are required.")
    staging.mkdir(parents=True)
    # Keep the Quarto project outside this repository's ignored .opencode tree.
    # Otherwise nested websites with implicit render targets can be skipped by
    # Quarto's parent Git-ignore discovery, despite a successful exit status.
    staged_site = Path(tempfile.mkdtemp(prefix="tidystata-personal-site-")) / "source"
    baseline = snapshot(personal_site)
    shutil.copytree(personal_site, staged_site,
                    ignore=lambda directory, names: [n for n in names if n in EXCLUDED])
    if snapshot(staged_site) != baseline:
        raise ValueError("Personal site changed during preparation; retry from a fresh snapshot.")
    names = [*SOURCE_FILES, *[n for n in OPTIONAL_SOURCES if (staged_site / n).is_file()]]
    originals = {name: (staged_site / name).read_text(encoding="utf-8") for name in names}
    for name, text in patch_sources(originals).items():
        (staged_site / name).write_text(text, encoding="utf-8")
    shutil.copytree(book_site, staged_site / "docs/stata-to-r", dirs_exist_ok=True)
    before = embedded_files(staged_site)
    for i in (1, 2):
        run(protected(["quarto", "render", "--no-clean"], staging / "logs"), staged_site,
            staging / f"render-{i}.log", environment)
        if embedded_files(staged_site) != before:
            raise ValueError(f"Embedded book, slides or domain changed during site render {i}.")
    for name in ("books", "software"):
        text = (staged_site / "docs" / (name + ".html")).read_text(encoding="utf-8")
        if BOOK_PATH not in text:
            raise ValueError(f"Rendered {name} page is missing its reference link.")
    if (staged_site / "zh/_quarto.yml").is_file():
        run(protected(["quarto", "render", "--no-clean"], staging / "logs"), staged_site / "zh",
            staging / "render-zh.log", environment)
        for name in ("books", "software"):
            if "zh/" + name + ".qmd" in originals:
                text = (staged_site / "docs/zh" / (name + ".html")).read_text(encoding="utf-8")
                if "../stata-to-r/zh/index.html" not in text:
                    raise ValueError(f"Rendered Chinese {name} page is missing its reference link.")
    if snapshot(personal_site) != baseline:
        raise ValueError("Personal site changed during preparation; retry from a fresh snapshot.")
    files = [*patch_sources(originals)]
    files += [path.relative_to(staged_site).as_posix() for path in (staged_site / "docs").rglob("*") if path.is_file()]
    updates = []
    for name in sorted(set(files)):
        new = staged_site / name
        if fingerprint(new) != baseline.get(name):
            updates.append({"path": name, "before": baseline.get(name), "after": fingerprint(new)})
    apply_source = export_updates(staging, staged_site, updates)
    record = {"personal_site": str(personal_site), "staged_site": str(apply_source),
              "rendered_site": str(staged_site), "updates": updates,
              "site_render_passes": 2, "embedded_files_preserved": len(before), "status": "prepared",
              "baseline": baseline}
    (staging / "integration.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    print(f"Prepared {len(updates)} local file updates; {len(before)} embedded files preserved twice.", flush=True)
    return staging / "integration.json"


def apply_prepared(receipt):
    receipt = Path(receipt).resolve()
    record = json.loads(receipt.read_text(encoding="utf-8"))
    personal_site, staged_site = Path(record["personal_site"]).resolve(), Path(record["staged_site"]).resolve()
    if snapshot(personal_site) != record["baseline"]:
        raise ValueError("Personal site changed since preparation; prepare again before applying.")
    for entry in record["updates"]:
        target, source = (personal_site / entry["path"]).resolve(), (staged_site / entry["path"]).resolve()
        if personal_site not in target.parents or staged_site not in source.parents:
            raise ValueError("Integration path escaped its verified roots.")
        if fingerprint(target) != entry["before"] or fingerprint(source) != entry["after"]:
            raise ValueError(f"File changed since preparation: {entry['path']}")
    # Verify the entire update set before making the first write.
    for entry in record["updates"]:
        target, source = personal_site / entry["path"], staged_site / entry["path"]
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    # Seed the ignored cache so even the first subsequent site render is safe.
    import importlib.util
    spec = importlib.util.spec_from_file_location("preserve_embedded", HERE / "preserve-embedded.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.preserve(personal_site, "save")
    record["status"] = "applied"
    receipt.write_text(json.dumps(record, indent=2), encoding="utf-8")
    print(f"Applied {len(record['updates'])} local updates. No files deleted, committed or published.")


def integrate(personal_site, book_site, staging, run, protected, environment):
    receipt = prepare(personal_site, book_site, staging, run, protected, environment)
    apply_prepared(receipt)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--personal-site", type=Path)
    parser.add_argument("--book", type=Path)
    parser.add_argument("--staging", type=Path)
    parser.add_argument("--apply-prepared", type=Path)
    args = parser.parse_args()
    if args.apply_prepared:
        apply_prepared(args.apply_prepared)
    else:
        if not all((args.personal_site, args.book, args.staging)):
            parser.error("Supply --personal-site, --book and --staging, or --apply-prepared.")
        import os
        from build import run, protected
        environment = os.environ.copy()
        environment.update(LC_ALL="C", LANGUAGE="en", LOCALAPPDATA=str(args.staging.resolve() / "local-cache"))
        prepare(args.personal_site, args.book, args.staging, run, protected, environment)


if __name__ == "__main__":
    main()
