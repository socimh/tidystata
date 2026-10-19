"""Derive and validate the floor matrix from DESCRIPTION and reviewed companions."""
import argparse
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
FIELDS = ("Imports", "Suggests", "LinkingTo")


def dcf(text):
    fields = {}
    current = None
    for line in text.splitlines():
        if line.startswith((" ", "\t")) and current:
            fields[current] += " " + line.strip()
        elif ":" in line:
            current, value = line.split(":", 1)
            fields[current] = value.strip()
    return fields


def requirements(fields, names=FIELDS):
    result = []
    for field in names:
        for entry in fields.get(field, "").split(","):
            match = re.fullmatch(r"\s*([\w.]+)\s*(?:\((>=|<=|==|>|<)\s*([\d.\-]+)\))?\s*", entry)
            if match:
                result.append((field, *match.groups()))
            elif entry.strip():
                raise ValueError("Unrecognised dependency: " + entry)
    return result


def version(value):
    return tuple(map(int, re.split(r"[.\-]", value)))


def satisfies(actual, operator, expected):
    left, right = version(actual), version(expected)
    width = max(len(left), len(right))
    left += (0,) * (width - len(left))
    right += (0,) * (width - len(right))
    return {">=": left >= right, "<=": left <= right, "==": left == right,
            ">": left > right, "<": left < right}[operator]


def matrix(description, config):
    bounded = [(field, name, operator, bound) for field, name, operator, bound
               in requirements(dcf(description)) if operator]
    if any(operator != ">=" for _, _, operator, _ in bounded):
        raise ValueError("Review newly introduced non-minimum version constraints")
    bounds = {name: (field, bound) for field, name, _, bound in bounded}
    if len(bounds) != len(bounded):
        raise ValueError("Review duplicate version-bound declarations")
    if set(bounds) != set(config["cases"]):
        raise ValueError("Floor coverage differs from DESCRIPTION: " +
                         str(set(bounds) ^ set(config["cases"])))
    rows = []
    for package, (field, declared) in sorted(bounds.items()):
        case = config["cases"][package]
        if not satisfies(case["declared"], "==", declared):
            raise ValueError("Changed declared floor: " + package)
        if case["classification"] != "exact":
            # A new effective-bound exception requires a reviewed resolver change,
            # rather than quietly accepting a newer package as floor evidence.
            raise ValueError("Unreviewed effective boundary: " + package)
        if not satisfies(case["version"], "==", declared):
            raise ValueError("Candidate differs from declared floor: " + package)
        pins = dict(config["cohort"])
        pins.update(case["companions"])
        pins[package] = case["version"]
        for name, pinned in pins.items():
            key = name + "@" + pinned
            if key not in config["upstream"]:
                raise ValueError("Missing upstream DESCRIPTION evidence: " + key)
            metadata = config["upstream"][key]
            if not satisfies(metadata["Version"], "==", pinned):
                raise ValueError("Upstream version mismatch: " + key)
            for _, dependency, operator, required in requirements(
                    metadata, ("Depends", "Imports", "LinkingTo")):
                if dependency in pins and operator and not satisfies(pins[dependency], operator, required):
                    raise ValueError(f"Infeasible companion: {key} requires {dependency} {operator}{required}; pinned {pins[dependency]}")
        for name, (_, bound) in bounds.items():
            if not satisfies(pins[name], ">=", bound):
                raise ValueError("Companion below statart floor: " + name)
        pending, ordered = set(pins), []
        while pending:
            ready = sorted(name for name in pending if not any(
                dependency in pending for _, dependency, _, _ in requirements(
                    config["upstream"][name + "@" + pins[name]],
                    ("Depends", "Imports", "LinkingTo"))))
            if not ready:
                raise ValueError("Cyclic companion dependencies: " + str(pending))
            ordered.extend(ready)
            pending.difference_update(ready)
        rows.append({"package": package, "declared": declared,
                     "version": case["version"], "field": field,
                     "classification": case["classification"], "pins": pins,
                     "install_order": ordered,
                     "reason": case.get("reason", "Exact declared boundary with reviewed companions.")})
    return {"include": rows}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", help="Emit one complete case instead of the matrix")
    args = parser.parse_args()
    config = json.loads((ROOT / ".opencode/dependency-minimums.json").read_text(encoding="utf-8"))
    result = matrix((ROOT / "DESCRIPTION").read_text(encoding="utf-8"), config)
    if args.case:
        result = next(row for row in result["include"] if row["package"] == args.case)
        result["optional_policy"] = config["optional_policy"]
    print(json.dumps(result, separators=(",", ":")))


if __name__ == "__main__":
    main()
