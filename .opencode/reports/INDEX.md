# Function Reports Index

Current development version: 0.2.0.9000. Reports contain actual console output.
A passing demo is not a passing full package test suite.

| Function | Description | Examples | Status | Report |
| --- | --- | ---: | --- | --- |
| browse | Browse data | 5 | PASS | [View](report_browse_0.2.0.9000.md) |
| codebook | Variable metadata | 6 | PASS | [View](report_codebook_0.2.0.9000.md) |
| conversion | Conversion and missing-value preparation | 4 | PASS | [View](report_conversion_0.2.0.9000.md) |
| cut | Numeric bins | 7 | PASS | [View](report_cut_0.2.0.9000.md) |
| fre | Frequencies and totals | 6 | PASS | [View](report_fre_0.2.0.9000.md) |
| row_egen | Row calculations | 8 | PASS | [View](report_row_egen_0.2.0.9000.md) |
| s_select | Selection and expressions | 6 | PASS | [View](report_s_select_0.2.0.9000.md) |
| summ | Summary statistics | 10 | PASS | [View](report_summ_0.2.0.9000.md) |
| tab | Frequency tables | 8 | PASS | [View](report_tab_0.2.0.9000.md) |
| tab1 | Separate frequency tables | 6 | PASS | [View](report_tab1_0.2.0.9000.md) |
| timer | Timing | 6 | PASS | [View](report_timer_0.2.0.9000.md) |

## Development reviews

- [milestone_contracts_0.2.0.9000.md](milestone_contracts_0.2.0.9000.md)
- [milestone_status_0.2.0.9000.md](milestone_status_0.2.0.9000.md)
- [project_status_2026-10-15.md](project_status_2026-10-15.md)
- [project_status_cleanup_2026-10-16.md](project_status_cleanup_2026-10-16.md)
- [project_status_cleanup_review_2026-10-16.md](project_status_cleanup_review_2026-10-16.md)
- [project_status_codebook_browse_acceptance_2026-10-16.md](project_status_codebook_browse_acceptance_2026-10-16.md)
- [project_status_codebook_browse_pdf_2026-10-16.md](project_status_codebook_browse_pdf_2026-10-16.md)
- [project_status_console_showcase_2026-10-16.md](project_status_console_showcase_2026-10-16.md)
- [project_status_core_stabilization_2026-10-16.md](project_status_core_stabilization_2026-10-16.md)
- [project_status_failure_triage_2026-10-16.md](project_status_failure_triage_2026-10-16.md)
- [project_status_git_comparison_2026-10-15.md](project_status_git_comparison_2026-10-15.md)
- [project_status_inspection_acceptance_2026-10-16.md](project_status_inspection_acceptance_2026-10-16.md)
- [project_status_r_style_adoption_2026-10-16.md](project_status_r_style_adoption_2026-10-16.md)
- [project_status_summ_tabstat_100_scenarios_2026-10-16.md](project_status_summ_tabstat_100_scenarios_2026-10-16.md)
- [project_status_summ_tabstat_acceptance_2026-10-16.md](project_status_summ_tabstat_acceptance_2026-10-16.md)
- [project_status_tabulation_acceptance_2026-10-16.md](project_status_tabulation_acceptance_2026-10-16.md)
- [project_status_test_stabilization_2026-10-16.md](project_status_test_stabilization_2026-10-16.md)

## Historical reports

- [report_browse.md](report_browse.md)
- [report_codebook.md](report_codebook.md)
- [report_cut.md](report_cut.md)
- [report_esttab.md](report_esttab.md)
- [report_fre.md](report_fre.md)
- [report_row_egen.md](report_row_egen.md)
- [report_s_select.md](report_s_select.md)
- [report_summ.md](report_summ.md)
- [report_tab.md](report_tab.md)
- [report_tab1.md](report_tab1.md)
- [report_timer.md](report_timer.md)

## Regeneration

Run `make demo-reports` from the project root.
The workflow builds native code in a fresh temporary copy and preserves historical reports.
