"""Publish the authoritative migration guide to installed and website locations."""

import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check without writing")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    source = (root / "MIGRATION.md").read_bytes()
    markdown = source.decode("utf-8")
    if "```{" in markdown or "~~~{" in markdown:
        raise ValueError("MIGRATION.md must use static, unevaluated code fences.")
    article = markdown.split("\n", 1)[1].lstrip() if markdown.startswith("# ") else markdown
    header = (
        '---\ntitle: "Migration guide"\n'
        'output: rmarkdown::html_document\n---\n\n'
        '<!-- Generated from MIGRATION.md by generate_migration.py. -->\n\n'
    ).encode("utf-8")
    outputs = {
        root / "inst/MIGRATION.md": source,
        root / "vignettes/articles/migration.Rmd": header + article.encode("utf-8"),
    }
    stale = []
    for path, content in outputs.items():
        if args.check:
            if not path.exists() or path.read_bytes() != content:
                stale.append(str(path.relative_to(root)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
    if stale:
        parser.exit(1, "Migration copies need regeneration: " + ", ".join(stale) + "\n")
    print("Migration copies are current." if args.check else "Generated migration copies.")


if __name__ == "__main__":
    main()
