"""Generate codebook/browse acceptance evidence after fresh installed checks."""
import csv
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / '.opencode/results'
PREFIX = 'codebook-browse-accepted'
FUNCTIONS = ('codebook', 'browse')


def read_csv(suffix):
    with (RESULTS / (PREFIX + suffix)).open(encoding='utf-8', newline='') as stream:
        return list(csv.DictReader(stream))


def totals(rows):
    return [len(rows), sum(int(r['passed']) for r in rows),
            sum(int(r['failed']) for r in rows), sum(r['error'] == 'TRUE' for r in rows),
            sum(int(r['warning']) for r in rows), sum(r['skipped'] == 'TRUE' for r in rows)]


def main():
    full = read_csv('.csv')
    family = [r for r in full if r['file'].startswith(('test-codebook', 'test-browse'))
              or r['file'] in ('test-complex_tb.R', 'test-s_select.R')]
    standalone = read_csv('-scenarios.csv')
    pattern = re.compile(r'^(codebook|browse) coverage (\d{3}): (.*)$')
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
               ('Codebook/browse acceptance and retained shared-selector checks', family), ('Full package', full)]
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
    assert 'R launcher exit: 0x00000000' in output and 'Touched R sources parsed successfully' in output
    for name in FUNCTIONS:
        assert f'NUMBERED COVERAGE {name} 100 scenarios' in output
    timing = re.search(r'SCENARIOS (\d+) ELAPSED ([0-9.]+) seconds', output)
    assert timing and int(timing.group(1)) == len(standalone)
    text = ['# Codebook and browse acceptance', '',
            'Verified 2026-10-16, statart 0.2.0.9000, Windows R 4.6.0.', '',
            '**100 numbered scenarios pass for codebook and 100 for browse.**',
            'The functions have separate matrices: 200 distinct scenario definitions/executions. Previous tests remain.',
            'Finite tests do not prove every possible input/platform or establish a code-coverage percentage.', '',
            '## Results', '',
            '| Scope | Blocks | Passing expectations | Failures | Errors | Uncaptured warnings | Skips |',
            '| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
    for label, rows in metrics:
        text.append('| ' + label + ' | ' + ' | '.join(map(str, totals(rows))) + ' |')
    text += ['', f'Standalone elapsed: {timing.group(2)} seconds. Fresh native installation and source build pass.',
             'R CMD check --no-manual: **Status: OK**, zero check errors, warnings or notes.',
             'Remaining full-suite diagnostics are outside this codebook/browse/shared-selector acceptance scope.', '',
             '## Reproduced defects and fixes', '',
             '- codebook on grouped/rowwise inputs could fail while reshaping group keys and statistics. It now ungroups before selection',
             '  and creates one inventory row per selected column. It describes the whole input, not separate group summaries.',
             '- SPSS user-missing codes and scalar missing list elements could inflate unique counts despite being excluded from n.',
             '  Counts and uniques now use the same original-column missingness mask before any distinct counting.',
             '- Matrix and nested-dataframe n previously counted measured cells rather than observations. Both counts now describe complete rows;',
             '  rows with any missing component are excluded, and row identities determine uniqueness.',
             '- A per-column implementation avoids the previous across/reshape failures for Unicode names. Existing rejection of duplicate,',
             '  empty or missing selected names is explicitly preserved so label alignment cannot become ambiguous.',
             '- Shared s_select probed both selection and transformation, then repeated the successful branch. It now caches the first success.',
             '  Successful selection callbacks and predicates are not repeated; fallback computation is not rerun. Successful warnings are replayed once,',
             '  failed-branch warnings are discarded as before, and both underlying errors remain available if neither branch works.',
             '- Four legacy wide-matrix fixtures now request minimal names before assigning their intended names, removing fixture-only warnings.',
             '- An initial hand-entered structured-count fixture contained two complete rows while its comment specified three.',
             '  The fixture was corrected to the intended rows; production counts were not changed to accommodate the fixture.',
             '  A new warning assertion was also corrected to recognize dplyr\'s normal wrapper while requiring one warning.', '',
             '## Contracts and boundaries', '',
             '- codebook returns an ungrouped tibble, ordered by selection: variable, optional label, type, n, unique.',
             '  Types and units are preserved in the inventory; input values, labels, attributes and grouping are unchanged.',
             '  Empty/all-missing columns retain zero-count rows; selecting no columns returns the typed empty inventory.',
             '- The inventory ignores row grouping before selection. Unlike the names helpers, omitted grouping keys are not automatically reinserted.',
             '  With no selection, grouping columns remain ordinary variables. Use summ/tabstat for group-specific numeric summaries.',
             '- List elements are whole identities: scalar NA/NaN are missing, while NULL, empty vectors and nested values remain elements.',
             '  Matrix/dataframe columns count complete observed rows, not individual cells. SPSS missingness follows the original is.na method.',
             '- browse returns the viewed/selected data invisibly with its dataframe class and grouping preserved; it does not return a name vector.',
             '  Headless R opens no viewer. The report explicitly prints returned values for readability.',
             '  GUI handoff, error propagation and a single viewer call are tested with stubs. A real interactive viewer was not visually validated.',
             '- Selection remains first, followed by data masking only after a failed selection. A failed selection can still execute user code before fallback.',
             '  This is not a global exactly-once guarantee for arbitrary callbacks. Precompute random or side-effecting columns with mutate, then select their names.',
             '  Numeric selection failures can remain valid computed constants; sequential computed-name overwrite follows existing transmute semantics.',
             '- s_select changed as required shared support; its retained tests and direct warning/error/evaluation regressions are included.',
             '  This pass provides numbered acceptance for codebook/browse, not a separate 100-case sign-off for every selector/type helper.',
             '- Optional haven/units/hms/bit64/data.table paths ran here. Absent Suggests may cause ordinary testthat skips elsewhere;',
             '  the standalone runner rejects all skips, failures, errors or uncaptured warnings.',
             '- Independent QA found no material remaining issue. These two functions are locally accepted within the documented/headless scope.',
             '  Real viewer validation, minimum R 4.1 and other platforms remain unverified. Next function family: conversion.',
             '- The approved console PDF is unchanged. No dependencies, exports, datasets or native artifacts changed.',
             '  No artifact deletion, push, merge, publication or release.', '', '## Numbered cases', '']
    for name in FUNCTIONS:
        text += [f'### {name}', '',
                 f'Source: [test-{name}-coverage.R](../../tests/testthat/test-{name}-coverage.R).', '',
                 '| ID | Scenario | Status | Passing expectations |', '| --- | --- | --- | ---: |']
        for identifier in range(1, 101):
            title, passes = numbered[name][identifier]
            text.append(f'| {identifier:03d} | {title.replace("|", "/")} | PASS | {passes} |')
        text.append('')
    actual = output.split('BEGIN ACTUAL OUTPUT\n', 1)[1].split('END ACTUAL OUTPUT', 1)[0].strip()
    actual = '\n'.join(line.rstrip() for line in actual.splitlines())
    text += ['## Actual installed-package output', '', '```text', actual, '```', '',
             '## Reproduce', '',
             'Run `python .opencode/workflows/verify_package.py --check --prefix .opencode/results/codebook-browse-accepted`.',
             'The workflow saves the fresh installed library path in codebook-browse-accepted-paths.json and uses the protected launcher.',
             'For focused tests only, use `--filter "^codebook|^browse|^complex_tb$|^s_select$"` without --check.',
             'Run `.opencode/tests/verify_codebook_browse.R <fresh-library-path> .opencode/results/codebook-browse-accepted` through the protected launcher',
             'with child LC_ALL=C/LANG=C; capture combined stdout/stderr as codebook-browse-accepted-examples.log.',
             'Regenerate this catalogue with `python .opencode/workflows/summarize_codebook_browse.py` after both runs.', '',
             'Evidence: [full suite](../results/codebook-browse-accepted.csv), [diagnostics](../results/codebook-browse-accepted-details.csv),',
             '[standalone cases](../results/codebook-browse-accepted-scenarios.csv), [actual output](../results/codebook-browse-accepted-examples.log),',
             '[package check](../results/codebook-browse-accepted-check.log).']
    report = ROOT / '.opencode/reports/project_status_codebook_browse_acceptance_2026-10-16.md'
    report.write_text('\n'.join(text) + '\n', encoding='utf-8')
    print(report)
    for label, rows in metrics:
        print(label, totals(rows))


if __name__ == '__main__':
    main()
