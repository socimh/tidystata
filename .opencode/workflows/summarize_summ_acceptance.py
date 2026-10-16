"""Generate the summary acceptance report from verified saved evidence."""
import csv
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / '.opencode/results'
PREFIX = 'summ-acceptance-clean'


def read_results(name):
    with (RESULTS / name).open(encoding='utf-8', newline='') as stream:
        return list(csv.DictReader(stream))


def totals(rows):
    return dict(blocks=len(rows), passed=sum(int(row['passed']) for row in rows),
                failed=sum(int(row['failed']) for row in rows),
                errors=sum(row['error'] == 'TRUE' for row in rows),
                warnings=sum(int(row['warning']) for row in rows),
                skipped=sum(row['skipped'] == 'TRUE' for row in rows))


def main():
    full = read_results(PREFIX + '.csv')
    focused = [row for row in full if row['file'].startswith('test-summ')]
    scenarios = read_results(PREFIX + '-scenarios.csv')
    full_totals, focused_totals, scenario_totals = map(totals, (full, focused, scenarios))
    for result in (full_totals, focused_totals, scenario_totals):
        assert result['failed'] == result['errors'] == 0, result
    assert focused_totals['warnings'] == focused_totals['skipped'] == 0
    assert scenario_totals['warnings'] == scenario_totals['skipped'] == 0
    counts = {name: sum(row['test'].startswith(name + ' ') for row in scenarios)
              for name in ('summ', 'tabstat')}
    assert min(counts.values()) >= 20, counts
    for step in ('install', 'tests', 'build', 'check'):
        log = (RESULTS / (PREFIX + '-' + step + '.log')).read_text(encoding='utf-8')
        assert 'R launcher exit: 0x00000000' in log, step
    assert 'Status: OK' in log
    output = (RESULTS / 'summ-acceptance-examples-clean.log').read_text(encoding='utf-8')
    assert 'R launcher exit: 0x00000000' in output
    elapsed = re.search(r'SCENARIOS \d+ ELAPSED ([0-9.]+) seconds', output).group(1)
    examples = output.split('BEGIN ACTUAL OUTPUT', 1)[1].split('END ACTUAL OUTPUT', 1)[0]
    examples = '\n'.join(line.rstrip() for line in examples.strip().splitlines())
    metrics = '\n'.join(f'| {label} | {result["blocks"]} | {result["passed"]} | '
                        f'{result["failed"]} | {result["errors"]} | {result["warnings"]} | {result["skipped"]} |'
                        for label, result in (('Full package', full_totals),
                                              ('All summary tests', focused_totals),
                                              ('Standalone acceptance', scenario_totals)))
    text = f'''# summ and tabstat acceptance review

Verified 2026-10-16 for version 0.2.0.9000 on Windows R 4.6.0.
**Assessment: both functions are locally accepted release candidates.**
Package publication still requires minimum-R and other-platform validation and
maintainer approval. No push, merge or release is included.

## Defects corrected

- SPSS discrete/range user-missing values are excluded consistently from counts,
  unique values and statistics before conversion removes missing-value metadata.
- Reserved grouping keys use unique dot-prefixed names with a message; original
  values and input data are preserved. Explicit .by overrides existing groups.
- Columns named .data or .env are evaluated as actual columns; tabstat vector
  input works and retains the caller's variable name.
- Compact datetime spreads round fractional seconds instead of failing.
- .keep_all retains counts/unique values for character and list columns, with
  numeric statistics NA, including character-only inputs. This was explicitly
  chosen by the maintainer; numeric-looking strings are not parsed.
- Single-variable .name=FALSE works for zero-row grouped output. Logical
  controls reject missing, nonscalar and nonlogical arguments clearly.
- Matrix/data-frame columns fail with an actionable diagnostic.
- Integer64 conversion precision warnings remain visible. Mixed-type notices
  no longer append a spurious FALSE suffix.

## Verification

| Scope | Blocks | Passing expectations | Failures | Errors | Warnings | Skips |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
{metrics}

The standalone runner completes in {elapsed} seconds, with a 100% passing
scenario rate. It includes {counts['summ']} explicitly named summ scenarios and
{counts['tabstat']} tabstat scenarios, plus shared contract scenarios. The
independent numerical references cover ordinary/logical/asymmetric vectors,
missing data, SD/SE, quantiles, MAD/IQR, sums and the retained moment formulas.

| Area | Checks |
| --- | --- |
| Numerical/missing values | Base-R references, SPSS discrete/range and all-missing codes, within-group masks, input preservation |
| Input/output contracts | Vector input, type families, list/table output, grouped empty schemas, single/multiple measured variables |
| Selection and names | Existing groups, explicit override, missing group keys, reserved/dotted names, data-mask pronoun names |
| Argument boundaries | Statistic aliases/unsupported statistics, invalid logical flags, unsupported matrix columns, precision warnings |
| Nonnumeric retention | Character-only and mixed data, repeated list identities, counts without text parsing |
| Calendar output | Percentile aliases, empty inputs, mixed tables, compact sub-second spread, explicit calendar sum rejection |

Fresh native installation and source build pass. R CMD check --no-manual reports
**Status: OK**, with no check errors, warnings or notes. All retained summary
tests now capture expected warnings explicitly; the legacy unnamed-matrix
fixture was corrected without removing coverage. The remaining package warnings
and empty cut_length skip are outside these two functions.

Independent QA and final read-only package review found no remaining material
defects. Additional probes checked units/difftime, tagged missing values,
grouped special names, list NULL/NA identities, mixed empty schemas and
base-data.frame/data.table class restoration.

Raw evidence: [full suite]({ '../results/' + PREFIX + '.csv' }),
[warning details]({ '../results/' + PREFIX + '-details.csv' }),
[package check]({ '../results/' + PREFIX + '-check.log' }),
[acceptance scenarios]({ '../results/' + PREFIX + '-scenarios.csv' }), and
[actual output log](../results/summ-acceptance-examples-clean.log).

An initial new message assertion failed because it excluded the message's
normal trailing newline; its pattern was corrected and the full clean run
supersedes that diagnostic run. Earlier failed outputs remain local and ignored.

## Actual output

These examples use df = tibble(g = c("A", "A", "B", NA),
x = c(1, 3, NA_real_, 8)); other examples show their inputs directly.
Warnings for labelled/nonnumeric input and the grouping rename notice are
intentional and retained in the raw output log.

```text
{examples}
```

## Published contract limits

- Missing measured values are always omitted; .na.rm controls missing grouping
  keys only. valid_pct is a fraction from zero to one.
- Factors use level codes with a warning; units/difftime retain original units.
  Numeric calculations use doubles, so large integer64 values can lose precision
  and warn. Exact arbitrary-precision summaries are not provided.
- SD is sample SD; quantiles use type 7. Skewness and excess kurtosis standardize
  central moments by sample SD; exact Stata equivalence is not claimed.
  Undefined singleton/constant moments may be NA or NaN.
- Calendar locations/spreads are formatted strings in both modes. Dates omit
  fractional days, datetimes use UTC to minute precision, and spreads are
  rounded for display. Calendar sum/skew/kurtosis are unsupported.
- List mode returns a single table for one type family and a named list for
  mixed families. Table mode combines them with compatible text statistics.
- Scope remains 0.2.0.9000, 13 Imports and 40 exports. No dependencies, exports,
  datasets, native source/artifacts or unrelated function behavior changed.

## Reproduction

Run the protected fresh full check first, then use the library path recorded
in its paths JSON for the standalone runner. Save the runner's combined stdout/stderr
as UTF-8 to .opencode/results/summ-acceptance-examples-clean.log, including the
protected launcher's exit line, before generating the report:

```powershell
python .opencode/workflows/verify_package.py --check --prefix .opencode/results/summ-acceptance-clean
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript .opencode/tests/verify_summ_tabstat.R <fresh-library> .opencode/results/summ-acceptance-clean
python .opencode/workflows/summarize_summ_acceptance.py
```

Source help, NEWS and MIGRATION document the accepted behavior; man/summ.Rd was
regenerated. README examples were unchanged. Continue with the tabulation family
next; minimum-R/multi-platform validation remains a package publication gate.
'''
    destination = ROOT / '.opencode/reports/project_status_summ_tabstat_acceptance_2026-10-16.md'
    destination.write_text(text, encoding='utf-8')
    print('Summary readiness report:', destination.name)
    print('Full package:', full_totals)
    print('Summary tests:', focused_totals)
    print('Standalone:', scenario_totals, 'named scenarios:', counts)


if __name__ == '__main__':
    main()
