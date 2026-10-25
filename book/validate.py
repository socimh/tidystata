"""Audit rendered book content, assets and bilingual navigation without a browser."""
from collections import Counter
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
from urllib.parse import unquote, urlsplit


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.ids = []
        self.examples = []
        self.links = []
        self.language_link = None
        self.text = []
        self.code = {}
        self.markup = {}
        self.pre_markup = []
        self.current_example = None
        self.pre_language = None
        self.pre_text = []
        self.h1 = 0
        self.feed(path.read_text(encoding="utf-8"))

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.h1 += tag == "h1"
        if "id" in attrs:
            self.ids.append(attrs["id"])
        if "data-example-id" in attrs:
            self.examples.append(attrs["data-example-id"])
            self.current_example = attrs["data-example-id"]
        if tag == "pre" and self.current_example:
            classes = attrs.get("class", "").split()
            self.pre_language = next((x for x in ("stata", "r") if x in classes), None)
            self.pre_text = []
            self.pre_markup = []
        if tag == "span" and self.pre_language and attrs.get("class"):
            self.pre_markup.append(f"<{attrs['class']}>")
        if tag == "a" and attrs.get("href"):
            self.links.append(attrs["href"])
        if tag in ("script", "img") and attrs.get("src"):
            self.links.append(attrs["src"])
        if tag == "link" and attrs.get("href"):
            self.links.append(attrs["href"])
        if attrs.get("id") == "language-toggle":
            self.language_link = attrs.get("href")

    def handle_data(self, data):
        self.text.append(data)
        if self.pre_language:
            self.pre_text.append(data)
            self.pre_markup.append(data)

    def handle_endtag(self, tag):
        if tag == "pre" and self.pre_language:
            text = "".join(self.pre_text).rstrip("\n")
            self.code.setdefault(self.current_example, {})[self.pre_language] = hashlib.sha256(text.encode("utf-8")).hexdigest()
            # Highlighting is recorded so both editions can be compared token by token.
            self.markup.setdefault(self.current_example, {})[self.pre_language] = "".join(self.pre_markup)
            self.pre_language = None


def audit(site, manifest):
    site = Path(site).resolve()
    problems = []
    pages = {path.resolve(): Page(path) for path in site.rglob("*.html")}
    markup = {}
    for lang, prefix in (("en", ""), ("zh", "zh/")):
        directory = site / prefix
        chapter_files = ["index.html", "stata-index.html", "r-index.html"]
        chapter_files += [x["slug"] + ".html" for x in manifest["chapters"]]
        collected = []
        for filename in chapter_files:
            path = (directory / filename).resolve()
            if path not in pages:
                problems.append(f"Missing page: {prefix}{filename}")
                continue
            page = pages[path]
            collected.extend(page.examples)
            if page.h1 > 1:
                problems.append(f"Repeated h1 title in {prefix}{filename}: {page.h1}")
            duplicates = [key for key, n in Counter(page.ids).items() if n > 1]
            if duplicates:
                problems.append(f"Duplicate anchors in {prefix}{filename}: {duplicates[:3]}")
            target = ((site if lang == "zh" else site / "zh") / filename).resolve()
            if not page.language_link or (path.parent / page.language_link).resolve() != target:
                problems.append(f"Wrong language target: {prefix}{filename}")
        if Counter(collected) != Counter(manifest["examples"].keys()):
            problems.append(f"{lang}: example IDs missing or duplicated")
        for id_, location in manifest["examples"].items():
            filename, anchor = location.split("#", 1)
            page = pages.get((directory / filename).resolve())
            if page is None or anchor not in page.ids:
                problems.append(f"Missing deep link: {prefix}{location}")
            else:
                if "code_hashes" in manifest and page.code.get(id_) != manifest["code_hashes"][id_]:
                    problems.append(f"Changed example code: {prefix}{id_}")
                stata = page.markup.get(id_, {}).get("stata", "")
                if stata and not stata.lstrip().startswith("<kw>"):
                    problems.append(f"Stata command not highlighted: {prefix}{id_}")
                markup.setdefault(id_, set()).add(repr(page.markup.get(id_)))
        search_path = directory / "search.json"
        if not search_path.is_file():
            problems.append(f"Missing {lang} search index")
        else:
            records = json.loads(search_path.read_text(encoding="utf-8"))
            text = " ".join(str(r.get("text", "")) for r in records)
            for needle in ("ivreghdfe", "tabulate", "dplyr", "analytic") + (("缺失",) if lang == "zh" else ("missing",)):
                if needle not in text:
                    problems.append(f"{lang} search index does not include {needle}")
    unequal = [id_ for id_, versions in markup.items() if len(versions) > 1]
    if unequal:
        problems.append(f"Code highlighting differs between editions: {unequal[:5]}")
    for path, page in pages.items():
        for href in page.links:
            parsed = urlsplit(href)
            if parsed.scheme or parsed.netloc or href.startswith("/"):
                continue
            target = (path.parent / unquote(parsed.path)).resolve() if parsed.path else path
            if target.is_dir():
                target = target / "index.html"
            if not target.is_file():
                problems.append(f"Broken local link in {path.relative_to(site)}: {href}")
            elif parsed.fragment and target.suffix == ".html" and target in pages:
                if unquote(parsed.fragment) not in pages[target].ids:
                    problems.append(f"Broken anchor in {path.relative_to(site)}: {href}")
    if problems:
        raise ValueError("\n".join(problems[:60]))
    return {"pages": len(pages), "examples_per_edition": manifest["example_count"],
            "chapters_per_edition": len(manifest["chapters"]), "local_links_and_anchors": "passed",
            "language_targets": "passed", "search_indexes": "passed",
            "highlighting_matches_across_editions": "passed"}
