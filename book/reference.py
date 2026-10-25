"""Generate two Quarto books from tidystata's authoritative lookup resources."""
import collections
import csv
import hashlib
import json
from pathlib import Path
import re
import shutil

BASE_URL = "https://www.socimh.com/stata-to-r/"
PACKAGE_URL = "https://socimh.github.io/tidystata/"


def read_csv(path):
    with Path(path).open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def slug(label):
    return re.sub(r"[^a-z0-9]+", "-", label.lower()).strip("-")


def tr(lang, en, zh):
    return zh if lang == "zh" else en


def code(value):
    # Double backticks also accommodate Stata macro references in inline code.
    return "`` " + value + " ``"


def block(value, language):
    fence = "`" * max(3, max((len(x) + 1 for x in re.findall(r"`+", value)), default=3))
    return f"{fence}{language}\n{value}\n{fence}\n"


def drop_heading(text):
    # Quarto renders the front-matter title, so a leading level-1 heading would repeat it.
    return re.sub(r"\A# [^\n]*\n+", "", text)


def visible_examples(rows, metadata):
    preferred = [row for row in rows if metadata[row["id"]]["preferred"]]
    return preferred or [min(rows, key=lambda row: metadata[row["id"]]["priority"])]


def render_example(row, provenance, lang):
    meta = provenance[row["id"]]
    task = row["task_zh"] if lang == "zh" else row["task"]
    detail = row["detail_zh"] if lang == "zh" else row["detail"]
    equivalence = meta["equivalence"]
    package = f'[{tr(lang, "Package: ", "包：")}]{{.visually-hidden}}' + code(row["package"])
    lines = [f'::: {{#example-{row["id"]} .reference-example .status-{equivalence} '
             f'data-example-id="{row["id"]}"}}', "",
             '::: {.example-head}', "", f"[{task}]{{.example-task}}", "", ":::", "",
             '::: {.comparison}', "",
             '::: {.comparison-stata}', "", "[Stata]{.col-label}", "", block(row["stata"], "stata"),
             ":::", "", '::: {.comparison-r}', "", f"[R {package}]{{.col-label}}", "",
             block(row["r"], "r"), ":::", "", ":::", ""]
    if detail:
        # Only qualified examples are flagged; the tag links to the front-page explanation.
        if equivalence == "qualified":
            tip = tr(lang, "The R result can differ from Stata; the note explains how.",
                     "R 的结果可能与 Stata 不同，说明见注释。")
            tag = tr(lang, "Differs from Stata", "与 Stata 有差异")
            detail = f'[{tag}](index.qmd#example-labels "{tip}"){{.caveat-tag}} {detail}'
        lines.extend([f"::: {{.example-note .status-{equivalence}}}", "", detail, "", ":::", ""])
    lines.extend(['::: {.example-sources}\n'
                  f'[{tr(lang, "Stata reference", "Stata 参考")}]({meta["source"]}) · '
                  f'[{tr(lang, "R reference", "R 参考")}]({meta["r_source"]})',
                  ":::", "", ":::", ""])
    return "\n".join(lines)


def render_chapter(rows, provenance, metadata, lang, title):
    groups = collections.defaultdict(list)
    for row in rows:
        groups[row["command"]].append(row)
    lines = [tr(lang,
             "Start with the expanded example for each command. Open the variants for options "
             "and alternative R approaches. Read the qualifications before adapting the code.",
             "先查看各命令展开的示例，再按需展开其他选项及 R 实现。改写代码前，请阅读适用条件及差异说明。"), ""]
    for command in sorted(groups, key=lambda x: (x.casefold(), x)):
        examples = sorted(groups[command], key=lambda row: (
            metadata[row["id"]]["priority"], row["stata"], row["r"], row["id"]))
        lines.extend([f"## {code(command)}", ""])
        preferred = visible_examples(examples, metadata)
        for row in preferred:
            lines.append(render_example(row, provenance, lang))
        remaining = [row for row in examples if row not in preferred]
        if remaining:
            summary = tr(lang, f"{len(remaining)} more examples and alternatives",
                         f"另有 {len(remaining)} 个示例及替代实现")
            lines.extend(['<details class="reference-variants">', f"<summary>{summary}</summary>", ""])
            lines.extend(render_example(row, provenance, lang) for row in remaining)
            lines.extend(["</details>", ""])
    return "\n".join(lines)


def front_matter(title, filename, lang):
    counterpart = f"../{filename}" if lang == "zh" else f"zh/{filename}"
    current_url = BASE_URL + ("zh/" if lang == "zh" else "") + filename
    other_url = BASE_URL + ("" if lang == "zh" else "zh/") + filename
    header = (f'<link rel="canonical" href="{current_url}">\n'
              f'<link rel="alternate" hreflang="{("zh-CN" if lang == "en" else "en")}" '
              f'href="{other_url}">')
    return {"title": title, "include-in-header": [{"text": header}],
            "include-before-body": [{"text":
                f'<nav class="language-switch" aria-label="Language / 语言">'
                f'<a id="language-toggle" href="{counterpart}" '
                f'lang="{("zh-CN" if lang == "en" else "en")}" '
                f'hreflang="{("zh-CN" if lang == "en" else "en")}">'
                f'{("中文" if lang == "en" else "English")}</a></nav>'}]}


def write_page(directory, name, title, body, lang):
    metadata = json.dumps(front_matter(title, name + ".html", lang), ensure_ascii=False, indent=2)
    (directory / (name + ".qmd")).write_text("---\n" + metadata + "\n---\n\n" + body, encoding="utf-8")


def generate(root, destination, metadata):
    root, destination = Path(root), Path(destination)
    rows = read_csv(root / "inst/extdata/stata-to-r.csv")
    provenance = {x["id"]: x for x in read_csv(root / "inst/extdata/findit-provenance.csv")}
    functions = read_csv(root / "inst/extdata/r-functions.csv")
    ids = [row["id"] for row in rows]
    if len(set(ids)) != len(ids) or set(ids) != set(metadata) or set(ids) != set(provenance):
        raise ValueError("Catalogue, annotations and provenance must have identical unique IDs.")
    by_section = collections.defaultdict(list)
    for row in rows:
        by_section[row["section"]].append(row)
    chapters = [{"section": section, "slug": slug(section), "section_zh": by_section[section][0]["section_zh"]}
                for section in sorted(by_section)]
    if len({x["slug"] for x in chapters}) != len(chapters):
        raise ValueError("Chapter slug collision.")
    examples = {row["id"]: slug(row["section"]) + ".html#example-" + row["id"] for row in rows}
    commands = collections.defaultdict(list)
    for row in rows:
        commands[row["command"]].append(row)
    manifest = {"examples": examples, "chapters": chapters, "example_count": len(rows),
                "lookup_keys": len(commands), "r_functions": len(functions),
                "command_families": len({r["command"] for r in rows if provenance[r["id"]]["kind"] == "command"})}
    manifest["code_hashes"] = {
        row["id"]: {lang: hashlib.sha256(row[lang].rstrip("\n").encode("utf-8")).hexdigest()
                    for lang in ("stata", "r")} for row in rows}
    for lang in ("en", "zh"):
        directory = destination / lang
        directory.mkdir(parents=True, exist_ok=False)
        for asset in (root / "book/assets").iterdir():
            if asset.is_file():
                shutil.copy2(asset, directory / asset.name)
        title = tr(lang, "Stata to R Reference", "Stata 转 R 参考手册")
        chapter_files = [c["slug"] + ".qmd" for c in chapters]
        config = {
            # A website rather than a book: secondary pages become header tabs and the
            # sidebar lists only the subject chapters, without nested parts.
            "project": {"type": "website", "output-dir": "_book",
                        # Builds live in git-ignored folders, so list the pages explicitly.
                        "render": ["index.qmd", *chapter_files, "stata-index.qmd", "r-index.qmd"]},
            "lang": tr(lang, "en", "zh"),
            "website": {"title": title, "site-url": BASE_URL + ("zh/" if lang == "zh" else ""),
                        "repo-url": "https://github.com/socimh/tidystata", "repo-actions": ["issue"],
                        "search": {"location": "navbar", "type": "overlay", "show-item-context": False},
                        "page-navigation": True,
                        "navbar": {"pinned": True, "left": [
                            {"text": tr(lang, "Start here", "从这里开始"), "href": "index.qmd"},
                            {"text": tr(lang, "Command reference", "命令对照"), "href": chapter_files[0]},
                            {"text": tr(lang, "Stata index", "Stata 索引"), "href": "stata-index.qmd"},
                            {"text": tr(lang, "R index", "R 索引"), "href": "r-index.qmd"}],
                            "tools": [{"icon": "github", "href": "https://github.com/socimh/tidystata"}]},
                        "sidebar": {"style": "docked", "title": tr(lang, "Command reference", "命令对照"),
                                    "contents": chapter_files},
                        "page-footer": {"center": [
                            {"text": "tidystata", "href": PACKAGE_URL},
                            {"text": "Minghong Shen", "href": "https://www.socimh.com/"}]}},
            "format": {"html": {"theme": "cosmo", "css": "reference.css", "number-sections": False,
                                 "toc": True, "toc-depth": 2, "code-copy": True,
                                 "include-after-body": "reference.js", "highlight-style": "github",
                                 "mainfont": "system-ui, -apple-system, 'Segoe UI', 'Microsoft YaHei', sans-serif"}},
            "execute": {"enabled": False},
        }
        # A script include is HTML, not the JavaScript source itself.
        config["format"]["html"]["include-after-body"] = [{"text": '<script src="reference.js"></script>'}]
        config["project"]["resources"] = ["reference.js"]
        (directory / "_quarto.yml").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
        intro = drop_heading((root / f"book/content/{lang}/index.md").read_text(encoding="utf-8"))
        for key in ("example_count", "lookup_keys", "r_functions", "command_families"):
            intro = intro.replace("{{" + key + "}}", str(manifest[key]))
        write_page(directory, "index", title, intro, lang)
        for chapter in chapters:
            chapter_title = chapter["section_zh"] if lang == "zh" else chapter["section"]
            body = render_chapter(by_section[chapter["section"]], provenance, metadata, lang, chapter_title)
            write_page(directory, chapter["slug"], chapter_title, body, lang)
        index = [tr(lang, "Commands, functions, operators and prefixes are listed separately below. "
                    "The link opens a preferred example; its chapter contains further variants.",
                    "以下分别列出命令、函数、运算符和前缀。链接打开优先示例，所在章节提供其他用法。"), ""]
        kinds = [("command", "Commands", "命令"), ("function", "Functions", "函数"),
                 ("operator", "Operators", "运算符"), ("prefix", "Prefixes", "前缀")]
        for kind, en, zh in kinds:
            index.extend(["## " + tr(lang, en, zh), ""])
            for key in sorted(commands, key=lambda x: (x.casefold(), x)):
                candidates = [row for row in commands[key] if provenance[row["id"]]["kind"] == kind]
                if candidates:
                    row = visible_examples(candidates, metadata)[0]
                    task = row["task_zh"] if lang == "zh" else row["task"]
                    index.append(f'- [{code(key)}]({examples[row["id"]]}) — {task}')
            index.append("")
        write_page(directory, "stata-index", tr(lang, "Stata index", "Stata 索引"), "\n".join(index), lang)
        rindex = [tr(lang, "Descriptions include functions without a paired example. "
                     "A linked Stata name leads to the command index; this is a reference, not an installation list.",
                     "此索引也包含尚无配对示例的 R 函数。已关联的 Stata 名称链接到命令索引，这里并非需要安装的包清单。"), ""]
        for package in sorted({f["package"] for f in functions}, key=str.casefold):
            rindex.extend(["## " + code(package), ""])
            for function in sorted([f for f in functions if f["package"] == package], key=lambda x: x["function"].casefold()):
                description = function["description_zh"] if lang == "zh" else function["description"]
                rindex.append(f'- {code(function["function"] + "()")} — {description}')
                if function["stata"]:
                    rindex.append(f'  Stata: {code(function["stata"])}. [↗](stata-index.html)')
            rindex.append("")
        write_page(directory, "r-index", tr(lang, "R index", "R 索引"), "\n".join(rindex), lang)
    (destination / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    return manifest
