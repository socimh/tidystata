"""Build the numbered summ/tabstat catalogue from actual verified results."""
from collections import Counter
import csv
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / '.opencode/results'
PREFIX = 'summ-100-reviewed'


def read_csv(suffix):
    with (RESULTS / (PREFIX + suffix)).open(encoding='utf-8', newline='') as stream:
        return list(csv.DictReader(stream))


def totals(rows):
    return [len(rows), sum(int(row['passed']) for row in rows),
            sum(int(row['failed']) for row in rows), sum(row['error'] == 'TRUE' for row in rows),
            sum(int(row['warning']) for row in rows), sum(row['skipped'] == 'TRUE' for row in rows)]


def main():
    full = read_csv('.csv')
    summary = [row for row in full if row['file'].startswith('test-summ')]
    standalone = read_csv('-scenarios.csv')
    pattern = re.compile(r'^(summ|tabstat) coverage (\d{3}) \[([^]]+)\] (.*)$')
    numbered = {'summ': {}, 'tabstat': {}}
    for row in standalone:
        match = pattern.match(row['test'])
        if match:
            function, identifier, category, title = match.groups()
            identifier = int(identifier)
            assert identifier not in numbered[function], (function, identifier)
            assert int(row['failed']) == int(row['warning']) == 0, row
            assert row['error'] == row['skipped'] == 'FALSE', row
            numbered[function][identifier] = (category, title, int(row['passed']))
    for function, cases in numbered.items():
        assert sorted(cases) == list(range(1, 101)), function
    for identifier in range(1, 101):
        assert numbered['summ'][identifier][:2] == numbered['tabstat'][identifier][:2]
    metrics = [('Numbered matrix', [row for row in standalone if pattern.match(row['test'])]),
               ('Standalone acceptance, including retained checks', standalone),
               ('All summary tests', summary), ('Full package', full)]
    for label, rows in metrics:
        values = totals(rows)
        assert values[2] == values[3] == 0, (label, values)
        if label != 'Full package':
            assert values[4] == values[5] == 0, (label, values)
    for step in ('install', 'tests', 'build', 'check'):
        log = (RESULTS / (PREFIX + '-' + step + '.log')).read_text(encoding='utf-8')
        assert 'R launcher exit: 0x00000000' in log, step
    assert 'Status: OK' in log
    output = (RESULTS / (PREFIX + '-examples.log')).read_text(encoding='utf-8')
    assert 'R launcher exit: 0x00000000' in output
    assert 'NUMBERED COVERAGE summ 100 scenarios' in output
    assert 'NUMBERED COVERAGE tabstat 100 scenarios' in output
    timing = re.search(r'SCENARIOS (\d+) ELAPSED ([0-9.]+) seconds', output)
    assert timing and int(timing.group(1)) == len(standalone)
    rows = ['# 100 scenarios for summ and tabstat', '',
            'Verified 2026-10-16, version 0.2.0.9000, Windows R 4.6.0.', '',
            '**All 100 numbered scenarios pass for each function: 200 function/scenario executions.**',
            'The previous acceptance tests remain. This expands test coverage without changing package behavior.', '',
            'A scenario is one named test block; an expectation is an assertion inside it.',
            'The two functions run the same scenario separately. This is 100 distinct scenario definitions,',
            'not 200 different definitions and not a code-coverage percentage. No finite suite proves',
            'correctness for every input, platform or dependency version.', '',
            '## Results', '',
            '| Scope | Blocks | Passing expectations | Failures | Errors | Warnings | Skips |',
            '| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
    for label, cases in metrics:
        rows.append('| ' + label + ' | ' + ' | '.join(map(str, totals(cases))) + ' |')
    rows += ['', f'Standalone elapsed time: {timing.group(2)} seconds. Fresh install/source build pass;',
             'R CMD check --no-manual: **Status: OK**, zero check errors, warnings or notes.',
             'Uncaptured warnings and the empty cut_length skip belong to other function families.', '',
             '## Test sources and independent references', '',
             '- [001-050: numeric values, invariants, grouping and names](../../tests/testthat/test-summ-coverage-numeric.R)',
             '- [051-100: classes, types, calendars, selection and errors](../../tests/testthat/test-summ-coverage-structure.R)',
             '- [Earlier acceptance regressions](../../tests/testthat/test-summ-acceptance.R)',
             '- [SPSS missingness and numerical references](../../tests/testthat/test-summ-missing-statistics.R)',
             '- [Shared summary contracts](../../tests/testthat/test-summ-contracts.R)',
             '- [Retained summary tests](../../tests/testthat/test-summ.R)',
             '- [Standalone runner](../tests/verify_summ_tabstat.R)', '',
             'The numerical oracle uses documented base-R statistics, not statart helpers.',
             'Closed-form references test the 10,000-row mean/sum/sample SD. Metamorphic cases test',
             'permutation, duplication, translation and negative scaling. Group results use explicit',
             'expected values or independently calculated subsets. Calendar and invalid-input cases',
             'assert documented values, classes, diagnostics and input preservation.', '',
             'Independent review removed an overlapping logical case in favor of grouped logical',
             'proportions, and tightened exact extrema/nonzero checks for tiny magnitudes.',
             'Unicode names use ASCII Unicode escapes so Windows shell/locale conversion cannot',
             'collapse distinct names. No production defect was identified in this expansion.', '',
             '## Scenario catalogue', '',
             'Each row below is executed independently through both public entry points.', '',
             '| ID | Area | Expected behavior checked | summ | tabstat |',
             '| ---: | --- | --- | --- | --- |']
    for identifier in range(1, 101):
        category, title, passed = numbered['summ'][identifier]
        other = numbered['tabstat'][identifier][2]
        rows.append(f'| {identifier:03d} | {category} | {title} | PASS ({passed}) | PASS ({other}) |')
    rows += ['', 'Parentheses show passing expectations in that scenario, not additional scenarios.', '',
             '## Evidence and reuse', '',
             f'- [Full-suite results](../results/{PREFIX}.csv)',
             f'- [Warning and skip details](../results/{PREFIX}-details.csv)',
             f'- [All acceptance scenario results](../results/{PREFIX}-scenarios.csv)',
             f'- [Protected package-check log](../results/{PREFIX}-check.log)',
             f'- [Per-case PASS output and actual function examples](../results/{PREFIX}-examples.log)', '',
             'Run from the repository root:', '', '```powershell',
             f'python .opencode/workflows/verify_package.py --check --prefix .opencode/results/{PREFIX}',
             'python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript .opencode/tests/verify_summ_tabstat.R <fresh-library> .opencode/results/' + PREFIX,
             'python .opencode/workflows/summarize_summ_100.py', '```', '',
             "Use the fresh library path recorded in the paths JSON. Capture the standalone runner's",
             'combined stdout/stderr as UTF-8 in the linked examples log, including the protected',
             'launcher exit line, before regenerating this report. The runner enforces IDs 001-100',
             'exactly once per function and exits nonzero for a failed/warning/skipped scenario.',
             'Type-specific cases need the optional Suggests data.table, units and bit64 installed;',
             'ordinary testthat runs skip them if absent, but acceptance requires all cases to execute.', '',
             '## Readiness boundary', '',
             'Both functions remain locally accepted release candidates. Exact Stata equivalence,',
             'arbitrary integer precision and full calendar precision are not promised; see',
             '[the accepted contracts and limits](project_status_summ_tabstat_acceptance_2026-10-16.md).',
             'The declared R 4.1 minimum and other platforms still need validation before publishing.',
             'No push, merge, release or artifact deletion was performed.']
    destination = ROOT / '.opencode/reports/project_status_summ_tabstat_100_scenarios_2026-10-16.md'
    destination.write_text('\n'.join(rows) + '\n', encoding='utf-8')
    print('100 cases per function verified; report:', destination.name)
    for label, cases in metrics:
        print(label, totals(cases))


if __name__ == '__main__':
    main()
