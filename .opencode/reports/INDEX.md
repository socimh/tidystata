# Function Reports Index

Current development version: 0.2.0.9000. Reports contain actual console output.
A passing demo is not a passing full package test suite.

| Function | Description | Examples | Status | Report |
| --- | --- | ---: | --- | --- |
| browse | Browse data | 5 | PASS | [View](report_browse.md) |
| codebook | Variable metadata | 6 | PASS | [View](report_codebook.md) |
| containers | Table container preservation | 1 | PASS | [View](report_containers.md) |
| conversion | Conversion and missing-value preparation | 4 | PASS | [View](report_conversion.md) |
| cut | Numeric bins | 7 | PASS | [View](report_cut.md) |
| fre | Frequencies and totals | 6 | PASS | [View](report_fre.md) |
| problems2 | Historical problem repairs and examples | 14 | PASS | [View](report_problems2.md) |
| readiness | Remaining-issue triage and small repairs | 9 | PASS | [View](report_readiness.md) |
| row_egen | Row calculations | 11 | PASS | [View](report_row_egen.md) |
| s_select | Selection and expressions | 6 | PASS | [View](report_s_select.md) |
| special_print | Persistent table previews | 8 | PASS | [View](report_special_print.md) |
| summ | Summary statistics | 10 | PASS | [View](report_summ.md) |
| tab | Frequency tables | 8 | PASS | [View](report_tab.md) |
| tab1 | Separate frequency tables | 6 | PASS | [View](report_tab1.md) |
| textbook | Textbook alignment contracts | 6 | PASS | [View](report_textbook.md) |
| timer | Timing | 6 | PASS | [View](report_timer.md) |

## Regeneration

Run `make demo-reports` from the project root.
The workflow builds native code in a fresh temporary copy and refreshes the current reports.
