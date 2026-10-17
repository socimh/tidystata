# Persistent table previews: acceptance

Development version 0.2.0.9000. Verified 2026-10-16 (America/New_York).

## Outcome

The opt-in preview_table() wrapper retains every row and column while printing head/tail or evenly spaced positions. Its statart_preview class extends a tibble and preserves the resulting grouping through supported transformations. unpreview_table() removes only the display policy. Existing tabulation and summary defaults are unchanged.

The four archived print/slice helpers are restored as maintained functions. One-time printers invisibly return the original data; slicing really selects rows. The original archived implementation remains preserved.

## Verified results

- Full retained suite: **3,106 blocks / 16,992 passing expectations**.
- Preview contracts: **27 blocks / 318 passing expectations**.
- Zero failures, errors, uncaptured warnings or skips in both scopes.
- Fresh native installation, source build and R CMD check --no-manual: Status: OK.
- Installed standalone verification and required-dependency-only smoke pass.
- All twelve actual-output demos pass, including the eight-example preview demo.
- Pinned Air, parsing and lintr checks pass for 96 maintained R files.

## Behavior and compatibility

- Default: first five and last five rows. n is a total positive whole number or Inf; odd budgets favor the head. Both styles use the first row for n = 1. Short inputs never repeat rows.
- Preview positions are recalculated after edits. Complete data is used in calculations.
- Common dplyr edits, grouping, summaries/reframing, standard joins and tidyr pivots retain settings. Joins use the left table's policy; bind_rows uses the first table's policy.
- Explicit as_tibble/as.data.frame conversions remove the preview; vector extraction returns ordinary columns. Table column classes and labels remain intact.
- Support covers ordinary data frames and ordinary/grouped/rowwise tibbles. Other container subclasses and lazy tables require explicit conversion/collection. Lists of tables require mapping the wrapper. Direct vec_rbind and arbitrary third-party transformations are outside the persistence guarantee.
- Six public functions are added/restored: 46 exports in total. Required Imports remain 12; tibble >= 3.1.0 and pillar >= 1.8.0 declare the public printing API floors.

## Regressions caught before acceptance

Initial RED confirmed absent APIs. Focused failures then reproduced grouped rename class loss, pivot selector scope loss, narrow-footer overflow, ignored footer limits, misleading n=1 omission wording, and duplicate/empty column-name printing errors. Each was corrected and covered by assertions. Pivot selector callback counts match the corresponding upstream tidyr operation rather than assuming upstream evaluates once. Report regeneration also exposed and fixed a whitespace-trimming expression that removed literal trailing t characters from headings; regenerated headings and fences were verified.

## Contract catalogue

| Scenario | Passing expectations |
| --- | ---: |
| preview constructor retains every row and every column | 6 |
| default preview displays first five and last five rows | 4 |
| headtail uses a total budget with the odd row assigned to the head | 3 |
| interval previews span the current table including its endpoints | 2 |
| short tables and infinite budgets display all rows without duplicates | 20 |
| zero column tables retain their actual row count | 4 |
| preview arguments reject invalid budgets and styles | 36 |
| preview accepts base data frames and rejects unsupported containers | 7 |
| classed and list columns remain unchanged | 7 |
| wrapping again changes settings without stacking classes | 4 |
| printing returns the original object invisibly without mutation | 5 |
| explicit conversions remove preview without changing table values | 4 |
| ordinary dplyr edits retain values and preview settings | 33 |
| base subsetting and replacement retain preview on table results | 17 |
| printed row numbers refer to the edited table | 3 |
| grouping transitions preserve settings and correct grouping metadata | 12 |
| grouped row and column edits recompute groups as dplyr does | 24 |
| rowwise transitions and edits retain correct grouping | 10 |
| summaries preserve preview and follow requested output grouping | 16 |
| joins retain the left table policy and ordinary dplyr values | 22 |
| row binding uses first table settings and retains every row | 6 |
| pivots preserve settings while respecting their changed table structure | 7 |
| pivot selectors retain caller context without extra evaluations | 10 |
| preview omission footers respect width and footer limits | 7 |
| legacy slice helpers return real unique subsets | 21 |
| one time printers retain their original input and visibility | 12 |
| preview printing preserves duplicate and empty column names | 16 |

## Actual installed console output

```text
R launcher logs: C:\Users\socimh\AppData\Local\Temp\CodexRLogs\20261017T010040353776Z-783b95e6
special-print: ......................................# A tibble: 12 x 0
# ... 9 rows omitted in the middle; use print(x, n = Inf) to show all rows.
..................................................# A tibble: 3 x 5
  date       time                factor labelled  list
  <date>     <dttm>              <fct>  <dbl+lbl> <list>
1 2020-01-01 2020-01-01 00:00:00 b       1 [yes]  <int [3]>
2 2020-01-02 2020-01-01 00:00:01 a       2 [no]   <NULL>
3 2020-01-03 2020-01-01 00:00:02 <NA>   NA        <named list [1]>
......................................................................................................................................................................................................................................

== DONE ========================================================================

Verified preview blocks: 27
Passing expectations: 318

Complete data, first five and last five rows:
# A tibble: 30 x 2
      id value
   <int> <dbl>
 1     1     1
 2     2     4
 3     3     9
 4     4    16
 5     5    25
26    26   676
27    27   729
28    28   784
29    29   841
30    30   900
# ... 20 rows omitted in the middle; use print(x, n = Inf) to show all rows.

After filtering and sorting, positions belong to the new result:
# A tibble: 20 x 2
      id value
   <int> <dbl>
 1    30   900
 2    29   841
 3    28   784
 4    27   729
 5    26   676
16    15   225
17    14   196
18    13   169
19    12   144
20    11   121
# ... 10 rows omitted in the middle; use print(x, n = Inf) to show all rows.

The same data with five evenly spaced positions:
# A tibble: 30 x 2
      id value
   <int> <dbl>
 1     1     1
 8     8    64
16    16   256
23    23   529
30    30   900
# ... 25 rows omitted between displayed positions; use print(x, n = Inf) to
# show all rows.
PASS: installed preview contracts and selective output verified.
R launcher exit: 0x00000000; status: C:\Users\socimh\AppData\Local\Temp\CodexRLogs\20261017T010040353776Z-783b95e6.status.json
```

## Reproduction and limits

```powershell
python .opencode/workflows/verify_package.py --check --prefix .opencode/results/preview-final
python .opencode/workflows/verify_package.py --minimal --prefix .opencode/results/preview-minimal
python .opencode/workflows/verify_package.py --demos --prefix .opencode/results/preview-demos
python .opencode/workflows/check_style.py
```

Run .opencode/tests/verify_special_print.R with the fresh installed library path through the protected R launcher. Inspect both exit status and captured stderr. The report generator refuses incomplete or failing acceptance evidence.

Executed locally on Windows R 4.6.0 with installed dependencies. R 4.1, minimum dependency versions, and macOS/Linux execution remain pending. This feature controls console printing, not HTML widgets or GUI viewers. No push, merge, publication or release is included.
