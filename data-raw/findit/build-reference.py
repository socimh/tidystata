"""Rebuild the lookup resources from reviewed sources, without running examples.

The legacy CSV preserves existing examples. Reference JSON records carry original
examples, template roles, provenance and executable regression fixtures together.
Run verify-reference.R after rebuilding; generated files alone prove no checks.
"""
import csv
import hashlib
import io
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).resolve().parent


def read_csv(path):
    with path.open(encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream))


def write_csv(path, rows, fields):
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fields, quoting=csv.QUOTE_ALL,
                            lineterminator="\n", extrasaction="ignore")
    writer.writeheader()
    writer.writerows(rows)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(stream.getvalue(), encoding="utf-8", newline="")


def r_value(value, field=""):
    if value is None:
        return "NULL"
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, (int, float)):
        return str(int(value)) + "L" if field == "priority" else str(value)
    if isinstance(value, list):
        return "c(" + ", ".join(r_value(x) for x in value) + ")" if value else "character()"
    if isinstance(value, dict):
        return "list(" + ", ".join(r_value(k) + " = " + r_value(v, k)
                                    for k, v in value.items()) + ")"
    raise TypeError(type(value))


def build():
    entries = read_csv(SOURCE / "legacy.csv")
    provenance = read_csv(SOURCE / "legacy-provenance.csv")
    functions = read_csv(SOURCE / "functions.csv")
    if not functions or any(not any("\u3400" <= char <= "\u9fff"
                                    for char in row["description_zh"])
                            or "<U+" in row["description_zh"] for row in functions):
        raise ValueError("The R function dictionary contains invalid Chinese text")
    original_commands = {row["command"] for row in entries}
    old_meta = {row["id"]: row for row in provenance}
    canonical = {}
    for entry in entries:
        canonical.setdefault(entry["command"], dict(
            abbrev=entry["abbrev"], kind=old_meta[entry["id"]]["kind"]
        ))
    templates = {}
    fixtures = []
    pairs = {(row["stata"], row["r"]) for row in entries}
    identities = {row["id"]: (row["stata"], row["r"]) for row in entries}
    for path in sorted(SOURCE.glob("*-reference.json")):
        for row in json.loads(path.read_text(encoding="utf-8")):
            required = ["command", "stata", "r", "task", "task_zh", "source",
                        "r_source", "check", "meaning", "package"]
            if any(not row.get(name) for name in required):
                raise ValueError((path.name, "Missing content", row.get("stata")))
            if not isinstance(row.get("setup"), str):
                raise ValueError((path.name, "Missing fixture setup", row["stata"]))
            for name in ["task_zh", "section_zh", "detail_zh"]:
                text = row.get(name, "")
                if (name != "detail_zh" or row.get("detail")) and not any(
                        "\u3400" <= char <= "\u9fff" for char in text):
                    raise ValueError((path.name, row["stata"], name, "Missing Chinese text"))
                if any(ord(char) < 32 or char == "\ufffd" for char in text):
                    raise ValueError((path.name, row["stata"], name, "Corrupt text"))
            if "\n" in row["r"] or "\r" in row["r"]:
                raise ValueError((path.name, row["stata"], "Normalize R code before rebuilding"))
            pair = (row["stata"], row["r"])
            if not row.get("id") and pair in pairs:
                continue
            pairs.add(pair)
            signature = json.dumps([row["command"], row["stata"], row["r"]],
                                   ensure_ascii=False).encode("utf-8")
            ident = row.get("id") or "ref-" + hashlib.sha256(signature).hexdigest()[:16]
            if ident in identities:
                if identities[ident] != pair:
                    raise ValueError((path.name, ident, "Conflicting stable example ID"))
                continue
            identities[ident] = pair
            entry = {name: row.get(name, "") for name in entries[0]}
            entry["id"] = ident
            command = canonical.setdefault(row["command"], dict(
                abbrev=row["abbrev"], kind=row["kind"]
            ))
            entry["abbrev"] = command["abbrev"]
            entries.append(entry)
            provenance.append(dict(
                id=ident, kind=command["kind"], approach=row["approach"],
                equivalence=row["equivalence"], source=row["source"],
                r_source=row["r_source"], validation="executed"
            ))
            fields = ["variables", "meaning", "priority", "hints", "strings",
                      "aliases", "derived", "varlist", "expressions", "protect",
                      "output_aliases", "r_default"]
            spec = {name: row[name] for name in fields if name in row}
            spec["priority"] = int(spec.get("priority", 1))
            if row["command"] in original_commands:
                # Preserve the established ordering of legacy variations too,
                # including comma-hint choices such as tab, gen.
                spec["priority"] += 100
            if row["command"] == "tabulate":
                spec["hints"] = list(dict.fromkeys(
                    "generate" if hint == "gen" else hint
                    for hint in spec.get("hints", [])
                ))
            templates[ident] = spec
            fixtures.append(dict(id=ident, package=row["package"],
                                 setup=row["setup"], code=row["r"],
                                 check=row["check"],
                                 expected_warning=row.get("expected_warning", "")))
    ids = [entry["id"] for entry in entries]
    if len(ids) != len(set(ids)):
        raise ValueError("Duplicate stable example IDs")
    write_csv(ROOT / "inst/extdata/stata-to-r.csv", entries, list(entries[0]))
    write_csv(ROOT / "inst/extdata/findit-provenance.csv", provenance,
              list(provenance[0]))
    write_csv(ROOT / "inst/extdata/r-functions.csv", functions, list(functions[0]))
    write_csv(ROOT / "tests/testthat/fixtures/findit/reference.csv", fixtures,
              ["id", "package", "setup", "code", "check", "expected_warning"])
    code = ["# Generated by data-raw/findit/build-reference.py; edit reference JSON.",
            "findit_reference_specs <- function() {", "  list("]
    for i, (ident, spec) in enumerate(templates.items()):
        code.append("    " + r_value(ident) + " = list(")
        for j, (key, value) in enumerate(spec.items()):
            suffix = "," if j < len(spec) - 1 else ""
            code.append("      " + key + " = " + r_value(value, key) + suffix)
        code.append("    )" + ("," if i < len(templates) - 1 else ""))
    code.extend(["  )", "}", ""])
    (ROOT / "R/findit-reference-data.R").write_text("\n".join(code),
                                                  encoding="utf-8", newline="")
    print(f"{len(entries)} paired examples; {len(fixtures)} executable new fixtures")


if __name__ == "__main__":
    build()
