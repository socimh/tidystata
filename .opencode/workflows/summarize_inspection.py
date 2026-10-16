"""Generate the five-function inspection catalogue from installed-package evidence."""
import csv
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / '.opencode/results'
PREFIX = 'inspection-accepted'
FUNCTIONS = ('ds', 'ds_as_column', 'names_as_column', 'variables', 'variables_search')


def read_csv(suffix):
    with (RESULTS / (PREFIX + suffix)).open(encoding='utf-8', newline='') as stream:
        return list(csv.DictReader(stream))


def totals(rows):
    return [len(rows), sum(int(row['passed']) for row in rows),
            sum(int(row['failed']) for row in rows), sum(row['error'] == 'TRUE' for row in rows),
            sum(int(row['warning']) for row in rows), sum(row['skipped'] == 'TRUE' for row in rows)]


def main():
    full = read_csv('.csv')
    family = [row for row in full if row['file'] == 'test-names.R' or row['file'].startswith('test-inspection-')]
    standalone = read_csv('-scenarios.csv')
    pattern = re.compile(r'^(ds|ds_as_column|names_as_column|variables|variables_search) coverage (\d{3}): (.*)$')
    numbered = {name: {} for name in FUNCTIONS}
    for row in standalone:
        match = pattern.match(row['test'])
        if match:
            name, identifier, title = match.groups()
            identifier = int(identifier)
            assert identifier not in numbered[name], (name, identifier)
            numbered[name][identifier] = (title, int(row['passed']))
    for name, cases in numbered.items():
        assert sorted(cases) == list(range(1, 101)), name
    assert [(r['file'], r['test'], r['passed']) for r in family] == [
        (r['file'], r['test'], r['passed']) for r in standalone]
    metrics = [('Numbered matrix', [r for r in standalone if pattern.match(r['test'])]),
               ('All inspection acceptance and retained names tests', family), ('Full package', full)]
    for label, rows in metrics:
        values = totals(rows)
        assert values[2] == values[3] == 0, (label, values)
        if label != 'Full package':
            assert values[4] == values[5] == 0, (label, values)
    for stage in ('install', 'tests', 'build', 'check'):
        log = (RESULTS / (PREFIX + '-' + stage + '.log')).read_text(encoding='utf-8')
        assert 'R launcher exit: 0x00000000' in log, stage
    assert 'Status: OK' in log
    output = (RESULTS / (PREFIX + '-examples.log')).read_text(encoding='utf-8')
    assert 'R launcher exit: 0x00000000' in output
    assert 'Touched R sources parsed successfully' in output
    for name in FUNCTIONS:
        assert f'NUMBERED COVERAGE {name} 100 scenarios' in output
    timing = re.search(r'SCENARIOS (\d+) ELAPSED ([0-9.]+) seconds', output)
    assert timing and int(timing.group(1)) == len(standalone)
    text = ['# Names and variable metadata acceptance', '',
            'Verified 2026-10-16, statart 0.2.0.9000, Windows R 4.6.0.', '',
            '**100 numbered scenarios pass independently for each of ds, ds_as_column, names_as_column, variables and variables_search.**',
            'The three name helpers share one 100-case selection matrix; metadata and search each have their own 100-case matrix.',
            'This is 300 scenario definitions and 500 function/scenario executions. Previous tests remain.',
            'Finite tests do not prove every possible input/platform or establish a code-coverage percentage.', '',
            '## Results', '',
            '| Scope | Blocks | Passing expectations | Failures | Errors | Uncaptured warnings | Skips |',
            '| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
    for label, rows in metrics:
        text.append('| ' + label + ' | ' + ' | '.join(map(str, totals(rows))) + ' |')
    text += ['', f'Standalone elapsed: {timing.group(2)} seconds. Fresh native installation and source build pass.',
             'R CMD check --no-manual: **Status: OK**, zero check errors, warnings or notes.',
             'Remaining full-suite diagnostics are outside this inspection acceptance scope.', '',
             '## Changes and preserved behavior', '',
             '- variables_search now validates a single non-missing character query. Invalid types, zero-length, vector and NA queries error clearly;',
             '  they previously failed in lower-level functions or silently recycled/returned no matches. The empty string still matches all variables.',
             '- The shared range translator now returns valid letter ranges before attempting numeric conversion.',
             '  This removes the spurious NAs-introduced warning for variables_search and s_match without changing their matches.',
             '  Dedicated regressions failed against the baseline and pass against the fresh fixed installation.',
             '- No behavior changes were needed in ds, ds_as_column, names_as_column or variables.',
             '  Two legacy wide-matrix fixtures now request minimal names before assigning their intended column names, eliminating fixture-only warnings.',
             '- Source help now documents existing-column tidyselect inputs, exact return containers, grouping retention, labels and search limits.',
             '  Misleading data-masking wording was corrected; no computed-column feature was added.',
             '- Source-based help was regenerated in an isolated directory and help examples executed successfully.',
             '  No unrelated generated help files were changed.', '',
             '## Contracts and boundaries', '',
             '- ds returns a character vector. The two column aliases return an identical one-column tibble named name.',
             '  Expected names are explicit fixture values; full vector/tibble identity checks include order, container and column type.',
             '- Selectors, renames and grouping-key retention follow dplyr::select. Grouped empty selections can retain keys;',
             '  ungroup first when the varlist must exclude them. Input rows, values, attributes and grouping remain unchanged.',
             '- variables returns name plus a label column only if at least one selected variable has a usable scalar label attribute.',
             '  Missing, empty or multivalue labels become NA; nonempty scalar labels are coerced to character.',
             '  Selection and renaming preserve label alignment. Names/metadata remain available even with no observations.',
             '- Search is case-insensitive and matches substrings of names or variable labels, never cell contents or value-label maps.',
             '  Explicit anchors require a complete name/label match. Existing * / ? / ~ wildcards and a single letter/numeric range remain supported.',
             '  Anchored numeric ranges, alternation, Unicode, selection-before-search and label-only matches have independent checks.',
             '  This translated language is not a general-purpose regex interface; multiple ranges and malformed patterns remain errors.',
             '- Queries containing several search alternatives can use the existing alternation syntax in one string; query vectors are not supported.',
             '- Optional data.table coverage ran here; absent Suggests can cause ordinary testthat skips elsewhere.',
             '  The standalone runner rejects every skip, failure, error or uncaptured warning.',
             '- The previously approved console PDF is unchanged. These five helpers are locally accepted release candidates within these boundaries.',
             '  codebook and browse are the next inspection pass. Minimum R 4.1 and other platforms remain unverified publication gates.',
             '- No dependencies, exports, datasets or native artifacts changed. The early QA graphics probe artifact was preserved in ignored results,',
             '  outside package tests. No deletion, push, merge, publication or release.', '',
             '## Numbered cases', '']
    groups = [(('ds', 'ds_as_column', 'names_as_column'), 'names'),
              (('variables',), 'metadata'), (('variables_search',), 'metadata')]
    for names, source in groups:
        text += ['### ' + ' / '.join(names), '',
                 f'Source: [test-inspection-coverage-{source}.R](../../tests/testthat/test-inspection-coverage-{source}.R).', '',
                 '| ID | Scenario | Status | Passing expectations (' + '/'.join(names) + ') |',
                 '| --- | --- | --- | ---: |']
        for identifier in range(1, 101):
            title = numbered[names[0]][identifier][0]
            assert all(numbered[name][identifier][0] == title for name in names)
            passes = '/'.join(str(numbered[name][identifier][1]) for name in names)
            text.append(f'| {identifier:03d} | {title.replace("|", "/")} | PASS | {passes} |')
        text.append('')
    actual = output.split('BEGIN ACTUAL OUTPUT\n', 1)[1].split('END ACTUAL OUTPUT', 1)[0].strip()
    actual = '\n'.join(line.rstrip() for line in actual.splitlines())
    text += ['## Actual installed-package output', '', '```text', actual, '```', '',
             '## Reproduce', '',
             'Run `python .opencode/workflows/verify_package.py --check --prefix .opencode/results/inspection-accepted`.',
             'The workflow saves the fresh installed library path in inspection-accepted-paths.json and invokes the protected launcher.',
             'For focused tests only, use `--filter "^names$|^inspection-"` without --check.',
             'Run `.opencode/tests/verify_inspection.R <fresh-library-path> .opencode/results/inspection-accepted` through the protected launcher',
             'with child LC_ALL=C/LANG=C; capture combined stdout/stderr as inspection-accepted-examples.log.',
             'Regenerate this report with `python .opencode/workflows/summarize_inspection.py` after both runs.', '',
             'Evidence: [full suite](../results/inspection-accepted.csv), [diagnostics](../results/inspection-accepted-details.csv),',
             '[standalone cases](../results/inspection-accepted-scenarios.csv), [actual output](../results/inspection-accepted-examples.log),',
             '[package check](../results/inspection-accepted-check.log).']
    report = ROOT / '.opencode/reports/project_status_inspection_acceptance_2026-10-16.md'
    report.write_text('\n'.join(text) + '\n', encoding='utf-8')
    print(report)
    for label, rows in metrics:
        print(label, totals(rows))


if __name__ == '__main__':
    main()
