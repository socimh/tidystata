"""Generate the tabulation catalogue from fresh installed-package evidence."""
import csv
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / '.opencode/results'
PREFIX = 'tabulation-accepted'
FUNCTIONS = ('tab', 'fre', 'tab1', 'fre1', 'tab2', 'fre2')


def read_csv(suffix):
    with (RESULTS / (PREFIX + suffix)).open(encoding='utf-8', newline='') as stream:
        return list(csv.DictReader(stream))


def totals(rows):
    return [len(rows), sum(int(row['passed']) for row in rows),
            sum(int(row['failed']) for row in rows), sum(row['error'] == 'TRUE' for row in rows),
            sum(int(row['warning']) for row in rows), sum(row['skipped'] == 'TRUE' for row in rows)]


def main():
    full = read_csv('.csv')
    family = [row for row in full if row['file'].startswith(('test-tab', 'test-fre'))]
    standalone = read_csv('-scenarios.csv')
    numbered = {function: {} for function in FUNCTIONS}
    pattern = re.compile(r'^(tab|fre|tab1|fre1|tab2|fre2) coverage (\d{3}): (.*)$')
    for row in standalone:
        match = pattern.match(row['test'])
        if match:
            function, identifier, title = match.groups()
            identifier = int(identifier)
            assert identifier not in numbered[function], (function, identifier)
            numbered[function][identifier] = (title, int(row['passed']))
    for function, cases in numbered.items():
        assert sorted(cases) == list(range(1, 101)), function
    for left, right in (('tab', 'fre'), ('tab1', 'fre1'), ('tab2', 'fre2')):
        for identifier in range(1, 101):
            assert numbered[left][identifier][0] == numbered[right][identifier][0]
    assert [(r['file'], r['test'], r['passed']) for r in family] == [
        (r['file'], r['test'], r['passed']) for r in standalone]
    metrics = [('Numbered matrix', [r for r in standalone if pattern.match(r['test'])]),
               ('All tabulation tests and shared conversion regressions', family), ('Full package', full)]
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
    assert 'Touched R sources parsed successfully' in output
    for function in FUNCTIONS:
        assert f'NUMBERED COVERAGE {function} 100 scenarios' in output
    timing = re.search(r'SCENARIOS (\d+) ELAPSED ([0-9.]+) seconds', output)
    assert timing and int(timing.group(1)) == len(standalone)
    text = ['# Tabulation function acceptance', '',
            'Verified 2026-10-16, statart 0.2.0.9000, Windows R 4.6.0.', '',
            '**100 numbered scenarios pass independently for each of tab, fre, tab1, fre1, tab2 and fre2.**',
            'Three paired matrices contain 300 distinct scenario definitions and 600 function/scenario executions.',
            'All previous tests remain. Finite tests do not prove correctness for every possible input.', '',
            '## Results', '',
            '| Scope | Blocks | Passing expectations | Failures | Errors | Uncaptured warnings | Skips |',
            '| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
    for label, rows in metrics:
        text.append('| ' + label + ' | ' + ' | '.join(map(str, totals(rows))) + ' |')
    text += ['', f'Standalone elapsed: {timing.group(2)} seconds. Parsing, fresh native installation and source build pass.',
             'R CMD check --no-manual: **Status: OK**, zero check errors, warnings or notes.',
             'Remaining full-suite diagnostics belong to other families; test warnings and package-check warnings are separate.', '',
             '## Reproduced defects and fixes', '',
             '- Explicit .by on an already grouped input retained an old group key and split counts incorrectly.',
             '  tab, fre, tab1 and fre1 now extract explicit groups from ungrouped data, then ungroup before preparation.',
             '  Inherited grouping still applies when .by is omitted. Joint case 057 and one-way case 058 fail on the baseline and pass after the fix.',
             '- Frequency rendering failed for haven_labelled vectors containing tagged missing values without value labels.',
             '  as_character now uses ordinary character conversion when labels are absent, avoiding haven::as_factor calling na_tag(NULL).',
             '  One-way case 092 and direct shared-helper regressions reproduce the baseline error and pass after the fix.',
             '- An initial NULL-list fixture assumed first-appearance sorting; it now verifies identity-associated counts.',
             '  Test-oracle corrections preserve raw SPSS identities and distinguish literal column name NA from missing row values.', '',
             '## Verified contracts and limitations', '',
             '- Counts use whole measured-row identities (joint), individual values (one-way), or two-dimensional cells (cross).',
             '  Base-R match/tabulate/table and explicit arithmetic provide independent oracles. Permutation and duplication checks add invariants.',
             '- percent/cum are percentages 0-100 within each group. valid uses observations with no missing measured fields;',
             '  missing group keys remain groups and are not themselves a reason to exclude a measurement. Empty selections retain established containers.',
             '- fre/fre1 insert synthetic rows whose cum is NA; observed categories, including Total, remain separate.',
             '  Frequency presentation converts a measured value key to character for labels (wide joint tables use a separate total column).',
             '  Distinct original values can display the same text, such as 0.1 + 0.2 and 0.3. Counts remain separate; use tab/tab1 to retain original types.',
             '- Cross-table combined-header collisions and literal NA alongside missing column categories remain explicit errors.',
             '  fre2 reserves the column category total. An observed row category total remains alongside the final marginal row; identify the final row by position.',
             '- Windows LC_CTYPE=C causes R/dplyr native-encoding warnings for some non-ASCII column names.',
             '  The affected cases narrowly assert those exact diagnostics while checking preserved names/counts; other warnings remain visible.',
             '  This is not a claim that execution emits no warnings in every locale. UTF-8 locale behavior and other platforms remain release checks.',
             '- Optional data.table/units/integer64/formatting paths depend on installed Suggests. They ran here; ordinary testthat runs may skip absent packages.',
             '  The standalone acceptance runner rejects any skips, failures, errors or uncaptured warnings.',
             '- No dependencies, exports, datasets or native artifacts changed. No push, merge, publication or release.',
             '  These six functions are locally accepted release candidates within the documented boundaries; minimum R 4.1 and other platforms remain unverified.', '',
             '## Numbered cases', '']
    for left, right, source in (('tab', 'fre', 'joint'), ('tab1', 'fre1', 'oneway'), ('tab2', 'fre2', 'cross')):
        text += [f'### {left} / {right}', '',
                 f'Source: [test-tab-coverage-{source}.R](../../tests/testthat/test-tab-coverage-{source}.R).', '',
                 f'| ID | Scenario | {left} | {right} | Passing expectations ({left}/{right}) |',
                 '| --- | --- | --- | --- | ---: |']
        for identifier in range(1, 101):
            title, passed_left = numbered[left][identifier]
            passed_right = numbered[right][identifier][1]
            text.append(f'| {identifier:03d} | {title.replace("|", "/")} | PASS | PASS | {passed_left}/{passed_right} |')
        text.append('')
    actual = output.split('BEGIN ACTUAL OUTPUT\n', 1)[1].split('END ACTUAL OUTPUT', 1)[0].strip()
    actual = '\n'.join(line.rstrip() for line in actual.splitlines())
    text += ['## Actual installed-package output', '', '```text', actual, '```', '',
             '## Reproduce and inspect', '',
             'Run `python .opencode/workflows/verify_package.py --check --prefix .opencode/results/tabulation-accepted` from the repository root.',
             'For tabulation only, use `--filter "^(tab|fre)"` without --check.',
             'The workflow invokes the protected launcher and saves the fresh library path in tabulation-accepted-paths.json.',
             'Run `.opencode/tests/verify_tabulation.R <fresh-library-path> .opencode/results/tabulation-accepted` through the protected launcher',
             'with child LC_ALL=C and LANG=C. Capture combined stdout/stderr as tabulation-accepted-examples.log, including launcher exit status.',
             'Regenerate this catalogue using `python .opencode/workflows/summarize_tabulation.py` after both runs.', '',
             'Evidence: [full suite](../results/tabulation-accepted.csv), [diagnostics](../results/tabulation-accepted-details.csv),',
             '[standalone cases](../results/tabulation-accepted-scenarios.csv), [output](../results/tabulation-accepted-examples.log),',
             '[package check](../results/tabulation-accepted-check.log).']
    report = ROOT / '.opencode/reports/project_status_tabulation_acceptance_2026-10-16.md'
    report.write_text('\n'.join(text) + '\n', encoding='utf-8')
    print(report)
    for label, rows in metrics:
        print(label, totals(rows))


if __name__ == '__main__':
    main()
