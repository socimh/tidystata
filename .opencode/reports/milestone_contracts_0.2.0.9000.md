# Verification: smaller statart core

**Version:** 0.2.0.9000
**Generated:** 2026-10-15 22:28:13 EDT
**Source:** `.opencode/tests/verify_milestone.R` and the milestone test files.

## Summary

| Measure | Count |
| --- | ---: |
| Scenarios | 622 |
| Passing scenarios | 622 |
| Failing scenarios | 0 |
| Skipped scenarios | 0 |
| Passing expectations | 4098 |
| Failed expectations | 0 |
| Error blocks | 0 |
| Warnings | 0 |
| Elapsed seconds including fresh native build | 59.52 |

## Contracts exercised

Character parsing and length; column labels and label search; grouped tabulations
and totals; data output defaults and explicit optional formatting; quantile
ties and validation; all ten row helpers with direct, selected, nested, empty,
missing, non-finite, and unsupported inputs. Cases include independent base-R
references and input-preservation checks, with at least 20 scenarios for each
changed public function. Review regressions cover reserved grouping keys and
general dataframe expressions evaluated once inside mutate().

Historical behavior changes: four wrappers retired; formatting defaults
changed; tied quantile values stay together; row outputs are atomic vectors.
See [migration guide](../../MIGRATION.md). This focused report does not claim
that the entire retained package test suite passes.

## Scenario results

| Scenario | Result |
| --- | --- |
| milestone as_numeric parses character values without losing positions | PASS |
| milestone variables searches attribute labels without a label column | PASS |
| milestone grouped tab1 keeps missing group keys and group counts | PASS |
| milestone fre1 adds totals within each retained group | PASS |
| milestone frequency defaults remain usable as data | PASS |
| milestone quantile ties stay together after row permutation | PASS |
| milestone row helpers return atomic vectors with explicit missing semantics | PASS |
| milestone reserved grouping count names retain independent keys | PASS |
| milestone as_numeric imported character integers | PASS |
| milestone as_numeric imported character decimals | PASS |
| milestone as_numeric imported character signs | PASS |
| milestone as_numeric imported character exponent | PASS |
| milestone as_numeric imported character dollars | PASS |
| milestone as_numeric imported character currency | PASS |
| milestone as_numeric imported character spaces | PASS |
| milestone as_numeric imported character negative_currency | PASS |
| milestone as_numeric imported character grouped_thousands | PASS |
| milestone as_numeric imported character embedded_units | PASS |
| milestone as_numeric imported character prefixes | PASS |
| milestone as_numeric imported character missing_middle | PASS |
| milestone as_numeric imported character missing_edges | PASS |
| milestone as_numeric imported character entirely_missing | PASS |
| milestone as_numeric imported character empty | PASS |
| milestone as_numeric imported character singleton | PASS |
| milestone as_numeric imported character nonnumeric | PASS |
| milestone as_numeric imported character mixed_nonnumeric | PASS |
| milestone as_numeric imported character blank_values | PASS |
| milestone as_numeric imported character zeros | PASS |
| milestone as_numeric imported character leading_zeros | PASS |
| milestone as_numeric imported character small_numbers | PASS |
| milestone as_numeric imported character large_numbers | PASS |
| milestone variables attribute metadata no_labels | PASS |
| milestone variables attribute metadata first_label | PASS |
| milestone variables attribute metadata last_label | PASS |
| milestone variables attribute metadata both_labels | PASS |
| milestone variables attribute metadata empty_label | PASS |
| milestone variables attribute metadata missing_label | PASS |
| milestone variables attribute metadata integer | PASS |
| milestone variables attribute metadata double | PASS |
| milestone variables attribute metadata logical | PASS |
| milestone variables attribute metadata factor | PASS |
| milestone variables attribute metadata ordered | PASS |
| milestone variables attribute metadata date | PASS |
| milestone variables attribute metadata datetime | PASS |
| milestone variables attribute metadata haven | PASS |
| milestone variables attribute metadata list_column | PASS |
| milestone variables attribute metadata zero_rows | PASS |
| milestone variables attribute metadata zero_columns | PASS |
| milestone variables attribute metadata unicode | PASS |
| milestone variables attribute metadata non_syntactic | PASS |
| milestone variables attribute metadata literal_label_column | PASS |
| milestone variables attribute metadata literal_name_column | PASS |
| milestone variables attribute metadata tibble | PASS |
| milestone codebook attribute metadata no_labels | PASS |
| milestone codebook attribute metadata first_label | PASS |
| milestone codebook attribute metadata last_label | PASS |
| milestone codebook attribute metadata both_labels | PASS |
| milestone codebook attribute metadata empty_label | PASS |
| milestone codebook attribute metadata missing_label | PASS |
| milestone codebook attribute metadata integer | PASS |
| milestone codebook attribute metadata double | PASS |
| milestone codebook attribute metadata logical | PASS |
| milestone codebook attribute metadata factor | PASS |
| milestone codebook attribute metadata ordered | PASS |
| milestone codebook attribute metadata date | PASS |
| milestone codebook attribute metadata datetime | PASS |
| milestone codebook attribute metadata haven | PASS |
| milestone codebook attribute metadata list_column | PASS |
| milestone codebook attribute metadata zero_rows | PASS |
| milestone codebook attribute metadata zero_columns | PASS |
| milestone codebook attribute metadata unicode | PASS |
| milestone codebook attribute metadata non_syntactic | PASS |
| milestone codebook attribute metadata literal_label_column | PASS |
| milestone codebook attribute metadata literal_name_column | PASS |
| milestone codebook attribute metadata tibble | PASS |
| milestone variables_search names and metadata label_only | PASS |
| milestone variables_search names and metadata label_case | PASS |
| milestone variables_search names and metadata label_wildcard | PASS |
| milestone variables_search names and metadata label_question | PASS |
| milestone variables_search names and metadata label_one_or_more | PASS |
| milestone variables_search names and metadata unicode | PASS |
| milestone variables_search names and metadata name_exact | PASS |
| milestone variables_search names and metadata name_case | PASS |
| milestone variables_search names and metadata name_wildcard | PASS |
| milestone variables_search names and metadata name_question | PASS |
| milestone variables_search names and metadata name_one_or_more | PASS |
| milestone variables_search names and metadata substring | PASS |
| milestone variables_search names and metadata no_match | PASS |
| milestone variables_search names and metadata all_names | PASS |
| milestone variables_search names and metadata empty_pattern | PASS |
| milestone variables_search names and metadata ordered_selection | PASS |
| milestone variables_search names and metadata selection_excludes_match | PASS |
| milestone variables_search names and metadata selection_includes_match | PASS |
| milestone variables_search names and metadata omitted_metadata | PASS |
| milestone variables_search names and metadata ignore_cell_content | PASS |
| milestone variables_search names and metadata mixed_name_and_label | PASS |
| milestone variables empty and reordered selection retain their metadata | PASS |
| milestone row_mean row semantics doubles | PASS |
| milestone row_mean row semantics integers | PASS |
| milestone row_mean row semantics logical | PASS |
| milestone row_mean row semantics mixed_storage | PASS |
| milestone row_mean row semantics partial_missing | PASS |
| milestone row_mean row semantics all_missing_row | PASS |
| milestone row_mean row semantics all_missing_data | PASS |
| milestone row_mean row semantics nan_and_na | PASS |
| milestone row_mean row semantics positive_infinity | PASS |
| milestone row_mean row semantics negative_infinity | PASS |
| milestone row_mean row semantics opposing_infinity | PASS |
| milestone row_mean row semantics one_column | PASS |
| milestone row_mean row semantics one_row | PASS |
| milestone row_mean row semantics duplicates | PASS |
| milestone row_mean row semantics negative_values | PASS |
| milestone row_mean row semantics large_values | PASS |
| milestone row_mean row semantics small_values | PASS |
| milestone row_mean row semantics zero_rows | PASS |
| milestone row_mean row semantics zero_columns | PASS |
| milestone row_mean row semantics entirely_empty | PASS |
| milestone row_mean row semantics null_input | PASS |
| milestone row_mean row semantics non_syntactic | PASS |
| milestone row_mean row semantics tibble | PASS |
| milestone row_mean row semantics mixed_missing_repeats | PASS |
| milestone row_sum row semantics doubles | PASS |
| milestone row_sum row semantics integers | PASS |
| milestone row_sum row semantics logical | PASS |
| milestone row_sum row semantics mixed_storage | PASS |
| milestone row_sum row semantics partial_missing | PASS |
| milestone row_sum row semantics all_missing_row | PASS |
| milestone row_sum row semantics all_missing_data | PASS |
| milestone row_sum row semantics nan_and_na | PASS |
| milestone row_sum row semantics positive_infinity | PASS |
| milestone row_sum row semantics negative_infinity | PASS |
| milestone row_sum row semantics opposing_infinity | PASS |
| milestone row_sum row semantics one_column | PASS |
| milestone row_sum row semantics one_row | PASS |
| milestone row_sum row semantics duplicates | PASS |
| milestone row_sum row semantics negative_values | PASS |
| milestone row_sum row semantics large_values | PASS |
| milestone row_sum row semantics small_values | PASS |
| milestone row_sum row semantics zero_rows | PASS |
| milestone row_sum row semantics zero_columns | PASS |
| milestone row_sum row semantics entirely_empty | PASS |
| milestone row_sum row semantics null_input | PASS |
| milestone row_sum row semantics non_syntactic | PASS |
| milestone row_sum row semantics tibble | PASS |
| milestone row_sum row semantics mixed_missing_repeats | PASS |
| milestone row_min row semantics doubles | PASS |
| milestone row_min row semantics integers | PASS |
| milestone row_min row semantics logical | PASS |
| milestone row_min row semantics mixed_storage | PASS |
| milestone row_min row semantics partial_missing | PASS |
| milestone row_min row semantics all_missing_row | PASS |
| milestone row_min row semantics all_missing_data | PASS |
| milestone row_min row semantics nan_and_na | PASS |
| milestone row_min row semantics positive_infinity | PASS |
| milestone row_min row semantics negative_infinity | PASS |
| milestone row_min row semantics opposing_infinity | PASS |
| milestone row_min row semantics one_column | PASS |
| milestone row_min row semantics one_row | PASS |
| milestone row_min row semantics duplicates | PASS |
| milestone row_min row semantics negative_values | PASS |
| milestone row_min row semantics large_values | PASS |
| milestone row_min row semantics small_values | PASS |
| milestone row_min row semantics zero_rows | PASS |
| milestone row_min row semantics zero_columns | PASS |
| milestone row_min row semantics entirely_empty | PASS |
| milestone row_min row semantics null_input | PASS |
| milestone row_min row semantics non_syntactic | PASS |
| milestone row_min row semantics tibble | PASS |
| milestone row_min row semantics mixed_missing_repeats | PASS |
| milestone row_max row semantics doubles | PASS |
| milestone row_max row semantics integers | PASS |
| milestone row_max row semantics logical | PASS |
| milestone row_max row semantics mixed_storage | PASS |
| milestone row_max row semantics partial_missing | PASS |
| milestone row_max row semantics all_missing_row | PASS |
| milestone row_max row semantics all_missing_data | PASS |
| milestone row_max row semantics nan_and_na | PASS |
| milestone row_max row semantics positive_infinity | PASS |
| milestone row_max row semantics negative_infinity | PASS |
| milestone row_max row semantics opposing_infinity | PASS |
| milestone row_max row semantics one_column | PASS |
| milestone row_max row semantics one_row | PASS |
| milestone row_max row semantics duplicates | PASS |
| milestone row_max row semantics negative_values | PASS |
| milestone row_max row semantics large_values | PASS |
| milestone row_max row semantics small_values | PASS |
| milestone row_max row semantics zero_rows | PASS |
| milestone row_max row semantics zero_columns | PASS |
| milestone row_max row semantics entirely_empty | PASS |
| milestone row_max row semantics null_input | PASS |
| milestone row_max row semantics non_syntactic | PASS |
| milestone row_max row semantics tibble | PASS |
| milestone row_max row semantics mixed_missing_repeats | PASS |
| milestone row_median row semantics doubles | PASS |
| milestone row_median row semantics integers | PASS |
| milestone row_median row semantics logical | PASS |
| milestone row_median row semantics mixed_storage | PASS |
| milestone row_median row semantics partial_missing | PASS |
| milestone row_median row semantics all_missing_row | PASS |
| milestone row_median row semantics all_missing_data | PASS |
| milestone row_median row semantics nan_and_na | PASS |
| milestone row_median row semantics positive_infinity | PASS |
| milestone row_median row semantics negative_infinity | PASS |
| milestone row_median row semantics opposing_infinity | PASS |
| milestone row_median row semantics one_column | PASS |
| milestone row_median row semantics one_row | PASS |
| milestone row_median row semantics duplicates | PASS |
| milestone row_median row semantics negative_values | PASS |
| milestone row_median row semantics large_values | PASS |
| milestone row_median row semantics small_values | PASS |
| milestone row_median row semantics zero_rows | PASS |
| milestone row_median row semantics zero_columns | PASS |
| milestone row_median row semantics entirely_empty | PASS |
| milestone row_median row semantics null_input | PASS |
| milestone row_median row semantics non_syntactic | PASS |
| milestone row_median row semantics tibble | PASS |
| milestone row_median row semantics mixed_missing_repeats | PASS |
| milestone row_var row semantics doubles | PASS |
| milestone row_var row semantics integers | PASS |
| milestone row_var row semantics logical | PASS |
| milestone row_var row semantics mixed_storage | PASS |
| milestone row_var row semantics partial_missing | PASS |
| milestone row_var row semantics all_missing_row | PASS |
| milestone row_var row semantics all_missing_data | PASS |
| milestone row_var row semantics nan_and_na | PASS |
| milestone row_var row semantics positive_infinity | PASS |
| milestone row_var row semantics negative_infinity | PASS |
| milestone row_var row semantics opposing_infinity | PASS |
| milestone row_var row semantics one_column | PASS |
| milestone row_var row semantics one_row | PASS |
| milestone row_var row semantics duplicates | PASS |
| milestone row_var row semantics negative_values | PASS |
| milestone row_var row semantics large_values | PASS |
| milestone row_var row semantics small_values | PASS |
| milestone row_var row semantics zero_rows | PASS |
| milestone row_var row semantics zero_columns | PASS |
| milestone row_var row semantics entirely_empty | PASS |
| milestone row_var row semantics null_input | PASS |
| milestone row_var row semantics non_syntactic | PASS |
| milestone row_var row semantics tibble | PASS |
| milestone row_var row semantics mixed_missing_repeats | PASS |
| milestone row_sd row semantics doubles | PASS |
| milestone row_sd row semantics integers | PASS |
| milestone row_sd row semantics logical | PASS |
| milestone row_sd row semantics mixed_storage | PASS |
| milestone row_sd row semantics partial_missing | PASS |
| milestone row_sd row semantics all_missing_row | PASS |
| milestone row_sd row semantics all_missing_data | PASS |
| milestone row_sd row semantics nan_and_na | PASS |
| milestone row_sd row semantics positive_infinity | PASS |
| milestone row_sd row semantics negative_infinity | PASS |
| milestone row_sd row semantics opposing_infinity | PASS |
| milestone row_sd row semantics one_column | PASS |
| milestone row_sd row semantics one_row | PASS |
| milestone row_sd row semantics duplicates | PASS |
| milestone row_sd row semantics negative_values | PASS |
| milestone row_sd row semantics large_values | PASS |
| milestone row_sd row semantics small_values | PASS |
| milestone row_sd row semantics zero_rows | PASS |
| milestone row_sd row semantics zero_columns | PASS |
| milestone row_sd row semantics entirely_empty | PASS |
| milestone row_sd row semantics null_input | PASS |
| milestone row_sd row semantics non_syntactic | PASS |
| milestone row_sd row semantics tibble | PASS |
| milestone row_sd row semantics mixed_missing_repeats | PASS |
| milestone row_unique row semantics doubles | PASS |
| milestone row_unique row semantics integers | PASS |
| milestone row_unique row semantics logical | PASS |
| milestone row_unique row semantics mixed_storage | PASS |
| milestone row_unique row semantics partial_missing | PASS |
| milestone row_unique row semantics all_missing_row | PASS |
| milestone row_unique row semantics all_missing_data | PASS |
| milestone row_unique row semantics nan_and_na | PASS |
| milestone row_unique row semantics positive_infinity | PASS |
| milestone row_unique row semantics negative_infinity | PASS |
| milestone row_unique row semantics opposing_infinity | PASS |
| milestone row_unique row semantics one_column | PASS |
| milestone row_unique row semantics one_row | PASS |
| milestone row_unique row semantics duplicates | PASS |
| milestone row_unique row semantics negative_values | PASS |
| milestone row_unique row semantics large_values | PASS |
| milestone row_unique row semantics small_values | PASS |
| milestone row_unique row semantics zero_rows | PASS |
| milestone row_unique row semantics zero_columns | PASS |
| milestone row_unique row semantics entirely_empty | PASS |
| milestone row_unique row semantics null_input | PASS |
| milestone row_unique row semantics non_syntactic | PASS |
| milestone row_unique row semantics tibble | PASS |
| milestone row_unique row semantics mixed_missing_repeats | PASS |
| milestone row_miss row semantics doubles | PASS |
| milestone row_miss row semantics integers | PASS |
| milestone row_miss row semantics logical | PASS |
| milestone row_miss row semantics mixed_storage | PASS |
| milestone row_miss row semantics partial_missing | PASS |
| milestone row_miss row semantics all_missing_row | PASS |
| milestone row_miss row semantics all_missing_data | PASS |
| milestone row_miss row semantics nan_and_na | PASS |
| milestone row_miss row semantics positive_infinity | PASS |
| milestone row_miss row semantics negative_infinity | PASS |
| milestone row_miss row semantics opposing_infinity | PASS |
| milestone row_miss row semantics one_column | PASS |
| milestone row_miss row semantics one_row | PASS |
| milestone row_miss row semantics duplicates | PASS |
| milestone row_miss row semantics negative_values | PASS |
| milestone row_miss row semantics large_values | PASS |
| milestone row_miss row semantics small_values | PASS |
| milestone row_miss row semantics zero_rows | PASS |
| milestone row_miss row semantics zero_columns | PASS |
| milestone row_miss row semantics entirely_empty | PASS |
| milestone row_miss row semantics null_input | PASS |
| milestone row_miss row semantics non_syntactic | PASS |
| milestone row_miss row semantics tibble | PASS |
| milestone row_miss row semantics mixed_missing_repeats | PASS |
| milestone row_non_miss row semantics doubles | PASS |
| milestone row_non_miss row semantics integers | PASS |
| milestone row_non_miss row semantics logical | PASS |
| milestone row_non_miss row semantics mixed_storage | PASS |
| milestone row_non_miss row semantics partial_missing | PASS |
| milestone row_non_miss row semantics all_missing_row | PASS |
| milestone row_non_miss row semantics all_missing_data | PASS |
| milestone row_non_miss row semantics nan_and_na | PASS |
| milestone row_non_miss row semantics positive_infinity | PASS |
| milestone row_non_miss row semantics negative_infinity | PASS |
| milestone row_non_miss row semantics opposing_infinity | PASS |
| milestone row_non_miss row semantics one_column | PASS |
| milestone row_non_miss row semantics one_row | PASS |
| milestone row_non_miss row semantics duplicates | PASS |
| milestone row_non_miss row semantics negative_values | PASS |
| milestone row_non_miss row semantics large_values | PASS |
| milestone row_non_miss row semantics small_values | PASS |
| milestone row_non_miss row semantics zero_rows | PASS |
| milestone row_non_miss row semantics zero_columns | PASS |
| milestone row_non_miss row semantics entirely_empty | PASS |
| milestone row_non_miss row semantics null_input | PASS |
| milestone row_non_miss row semantics non_syntactic | PASS |
| milestone row_non_miss row semantics tibble | PASS |
| milestone row_non_miss row semantics mixed_missing_repeats | PASS |
| milestone row_mean rejects unsupported columns without mutation | PASS |
| milestone row_sum rejects unsupported columns without mutation | PASS |
| milestone row_min rejects unsupported columns without mutation | PASS |
| milestone row_max rejects unsupported columns without mutation | PASS |
| milestone row_median rejects unsupported columns without mutation | PASS |
| milestone row_var rejects unsupported columns without mutation | PASS |
| milestone row_sd rejects unsupported columns without mutation | PASS |
| milestone row_unique rejects unsupported columns without mutation | PASS |
| milestone cut_quantile stable value boundaries quartiles | PASS |
| milestone cut_quantile stable value boundaries deciles | PASS |
| milestone cut_quantile stable value boundaries halves | PASS |
| milestone cut_quantile stable value boundaries one_interval | PASS |
| milestone cut_quantile stable value boundaries negative | PASS |
| milestone cut_quantile stable value boundaries fractional | PASS |
| milestone cut_quantile stable value boundaries uneven_sample | PASS |
| milestone cut_quantile stable value boundaries shuffled | PASS |
| milestone cut_quantile stable value boundaries missing_edges | PASS |
| milestone cut_quantile stable value boundaries missing_middle | PASS |
| milestone cut_quantile stable value boundaries nan_missing | PASS |
| milestone cut_quantile stable value boundaries two_values | PASS |
| milestone cut_quantile stable value boundaries two_values_collapsed | PASS |
| milestone cut_quantile stable value boundaries lower_plateau | PASS |
| milestone cut_quantile stable value boundaries upper_plateau | PASS |
| milestone cut_quantile stable value boundaries middle_plateau | PASS |
| milestone cut_quantile stable value boundaries plateau_with_missing | PASS |
| milestone cut_quantile stable value boundaries labels | PASS |
| milestone cut_quantile stable value boundaries collapsed_labels | PASS |
| milestone cut_quantile stable value boundaries integer_codes | PASS |
| milestone cut_quantile stable value boundaries collapsed_integer_codes | PASS |
| milestone cut_quantile stable value boundaries more_bins_than_rows | PASS |
| milestone cut_quantile stable value boundaries asymmetric_duplicates | PASS |
| milestone cut_quantile validates constant | PASS |
| milestone cut_quantile validates empty | PASS |
| milestone cut_quantile validates all_missing | PASS |
| milestone cut_quantile validates all_nan | PASS |
| milestone cut_quantile validates complex_values | PASS |
| milestone cut_quantile validates matrix_values | PASS |
| milestone cut_quantile validates character | PASS |
| milestone cut_quantile validates factor | PASS |
| milestone cut_quantile validates zero_bins | PASS |
| milestone cut_quantile validates negative_bins | PASS |
| milestone cut_quantile validates fractional_bins | PASS |
| milestone cut_quantile validates missing_bins | PASS |
| milestone cut_quantile validates infinite_bins | PASS |
| milestone cut_quantile validates character_bins | PASS |
| milestone cut_quantile validates vector_bins | PASS |
| milestone cut_quantile validates absent_bins | PASS |
| milestone cut_quantile validates short_labels | PASS |
| milestone cut_quantile validates long_labels | PASS |
| milestone cut_quantile validates collapsed_original_labels | PASS |
| milestone cut_quantile validates null_values | PASS |
| milestone tab1 preserves groups unequal_sizes | PASS |
| milestone tab1 preserves groups missing_key | PASS |
| milestone tab1 preserves groups entirely_missing_key | PASS |
| milestone tab1 preserves groups integer_keys | PASS |
| milestone tab1 preserves groups logical_keys | PASS |
| milestone tab1 preserves groups factor_keys | PASS |
| milestone tab1 preserves groups ordered_keys | PASS |
| milestone tab1 preserves groups date_keys | PASS |
| milestone tab1 preserves groups two_keys | PASS |
| milestone tab1 preserves groups two_missing_keys | PASS |
| milestone tab1 preserves groups non_syntactic_key | PASS |
| milestone tab1 preserves groups numeric_values | PASS |
| milestone tab1 preserves groups factor_values | PASS |
| milestone tab1 preserves groups ordered_values | PASS |
| milestone tab1 preserves groups logical_values | PASS |
| milestone tab1 preserves groups labelled_values | PASS |
| milestone tab1 preserves groups multiple_variables | PASS |
| milestone tab1 preserves groups existing_grouping | PASS |
| milestone tab1 preserves groups one_row_per_group | PASS |
| milestone tab1 preserves groups same_value_each_group | PASS |
| milestone tab1 preserves groups missing_values_group | PASS |
| milestone tab1 preserves groups reserved_n_key | PASS |
| milestone fre1 preserves groups unequal_sizes | PASS |
| milestone fre1 preserves groups missing_key | PASS |
| milestone fre1 preserves groups entirely_missing_key | PASS |
| milestone fre1 preserves groups integer_keys | PASS |
| milestone fre1 preserves groups logical_keys | PASS |
| milestone fre1 preserves groups factor_keys | PASS |
| milestone fre1 preserves groups ordered_keys | PASS |
| milestone fre1 preserves groups date_keys | PASS |
| milestone fre1 preserves groups two_keys | PASS |
| milestone fre1 preserves groups two_missing_keys | PASS |
| milestone fre1 preserves groups non_syntactic_key | PASS |
| milestone fre1 preserves groups numeric_values | PASS |
| milestone fre1 preserves groups factor_values | PASS |
| milestone fre1 preserves groups ordered_values | PASS |
| milestone fre1 preserves groups logical_values | PASS |
| milestone fre1 preserves groups labelled_values | PASS |
| milestone fre1 preserves groups multiple_variables | PASS |
| milestone fre1 preserves groups existing_grouping | PASS |
| milestone fre1 preserves groups one_row_per_group | PASS |
| milestone fre1 preserves groups same_value_each_group | PASS |
| milestone fre1 preserves groups missing_values_group | PASS |
| milestone fre1 preserves groups reserved_n_key | PASS |
| milestone fre data defaults and conserved counts balanced | PASS |
| milestone fre data defaults and conserved counts unequal_margins | PASS |
| milestone fre data defaults and conserved counts singleton | PASS |
| milestone fre data defaults and conserved counts sparse_cross | PASS |
| milestone fre data defaults and conserved counts integers | PASS |
| milestone fre data defaults and conserved counts doubles | PASS |
| milestone fre data defaults and conserved counts negative | PASS |
| milestone fre data defaults and conserved counts logical | PASS |
| milestone fre data defaults and conserved counts factor | PASS |
| milestone fre data defaults and conserved counts ordered | PASS |
| milestone fre data defaults and conserved counts date | PASS |
| milestone fre data defaults and conserved counts missing_x | PASS |
| milestone fre data defaults and conserved counts missing_y | PASS |
| milestone fre data defaults and conserved counts both_missing | PASS |
| milestone fre data defaults and conserved counts all_x_missing | PASS |
| milestone fre data defaults and conserved counts all_y_missing | PASS |
| milestone fre data defaults and conserved counts labelled | PASS |
| milestone fre data defaults and conserved counts unicode | PASS |
| milestone fre data defaults and conserved counts repeated_rows | PASS |
| milestone fre data defaults and conserved counts one_category | PASS |
| milestone fre data defaults and conserved counts data_frame | PASS |
| milestone fre1 data defaults and conserved counts balanced | PASS |
| milestone fre1 data defaults and conserved counts unequal_margins | PASS |
| milestone fre1 data defaults and conserved counts singleton | PASS |
| milestone fre1 data defaults and conserved counts sparse_cross | PASS |
| milestone fre1 data defaults and conserved counts integers | PASS |
| milestone fre1 data defaults and conserved counts doubles | PASS |
| milestone fre1 data defaults and conserved counts negative | PASS |
| milestone fre1 data defaults and conserved counts logical | PASS |
| milestone fre1 data defaults and conserved counts factor | PASS |
| milestone fre1 data defaults and conserved counts ordered | PASS |
| milestone fre1 data defaults and conserved counts date | PASS |
| milestone fre1 data defaults and conserved counts missing_x | PASS |
| milestone fre1 data defaults and conserved counts missing_y | PASS |
| milestone fre1 data defaults and conserved counts both_missing | PASS |
| milestone fre1 data defaults and conserved counts all_x_missing | PASS |
| milestone fre1 data defaults and conserved counts all_y_missing | PASS |
| milestone fre1 data defaults and conserved counts labelled | PASS |
| milestone fre1 data defaults and conserved counts unicode | PASS |
| milestone fre1 data defaults and conserved counts repeated_rows | PASS |
| milestone fre1 data defaults and conserved counts one_category | PASS |
| milestone fre1 data defaults and conserved counts data_frame | PASS |
| milestone fre2 data defaults and conserved counts balanced | PASS |
| milestone fre2 data defaults and conserved counts unequal_margins | PASS |
| milestone fre2 data defaults and conserved counts singleton | PASS |
| milestone fre2 data defaults and conserved counts sparse_cross | PASS |
| milestone fre2 data defaults and conserved counts integers | PASS |
| milestone fre2 data defaults and conserved counts doubles | PASS |
| milestone fre2 data defaults and conserved counts negative | PASS |
| milestone fre2 data defaults and conserved counts logical | PASS |
| milestone fre2 data defaults and conserved counts factor | PASS |
| milestone fre2 data defaults and conserved counts ordered | PASS |
| milestone fre2 data defaults and conserved counts date | PASS |
| milestone fre2 data defaults and conserved counts missing_x | PASS |
| milestone fre2 data defaults and conserved counts missing_y | PASS |
| milestone fre2 data defaults and conserved counts both_missing | PASS |
| milestone fre2 data defaults and conserved counts all_x_missing | PASS |
| milestone fre2 data defaults and conserved counts all_y_missing | PASS |
| milestone fre2 data defaults and conserved counts labelled | PASS |
| milestone fre2 data defaults and conserved counts unicode | PASS |
| milestone fre2 data defaults and conserved counts repeated_rows | PASS |
| milestone fre2 data defaults and conserved counts one_category | PASS |
| milestone fre2 data defaults and conserved counts data_frame | PASS |
| milestone optional frequency formatting remains explicit | PASS |
| milestone row_mean accepts an explicit pick within mutate | PASS |
| milestone row_mean accepts a data frame argument within mutate | PASS |
| milestone row_mean keeps selection errors visible within mutate | PASS |
| milestone row_sum accepts an explicit pick within mutate | PASS |
| milestone row_sum accepts a data frame argument within mutate | PASS |
| milestone row_sum keeps selection errors visible within mutate | PASS |
| milestone row_min accepts an explicit pick within mutate | PASS |
| milestone row_min accepts a data frame argument within mutate | PASS |
| milestone row_min keeps selection errors visible within mutate | PASS |
| milestone row_max accepts an explicit pick within mutate | PASS |
| milestone row_max accepts a data frame argument within mutate | PASS |
| milestone row_max keeps selection errors visible within mutate | PASS |
| milestone row_median accepts an explicit pick within mutate | PASS |
| milestone row_median accepts a data frame argument within mutate | PASS |
| milestone row_median keeps selection errors visible within mutate | PASS |
| milestone row_var accepts an explicit pick within mutate | PASS |
| milestone row_var accepts a data frame argument within mutate | PASS |
| milestone row_var keeps selection errors visible within mutate | PASS |
| milestone row_sd accepts an explicit pick within mutate | PASS |
| milestone row_sd accepts a data frame argument within mutate | PASS |
| milestone row_sd keeps selection errors visible within mutate | PASS |
| milestone row_unique accepts an explicit pick within mutate | PASS |
| milestone row_unique accepts a data frame argument within mutate | PASS |
| milestone row_unique keeps selection errors visible within mutate | PASS |
| milestone row_miss accepts an explicit pick within mutate | PASS |
| milestone row_miss accepts a data frame argument within mutate | PASS |
| milestone row_miss keeps selection errors visible within mutate | PASS |
| milestone row_non_miss accepts an explicit pick within mutate | PASS |
| milestone row_non_miss accepts a data frame argument within mutate | PASS |
| milestone row_non_miss keeps selection errors visible within mutate | PASS |
| milestone tab preserves counts and missing categories balanced | PASS |
| milestone optional formatted counts fre balanced | PASS |
| milestone optional formatted counts fre1 balanced | PASS |
| milestone optional formatted counts fre2 balanced | PASS |
| milestone tab preserves counts and missing categories unequal_margins | PASS |
| milestone optional formatted counts fre unequal_margins | PASS |
| milestone optional formatted counts fre1 unequal_margins | PASS |
| milestone optional formatted counts fre2 unequal_margins | PASS |
| milestone tab preserves counts and missing categories singleton | PASS |
| milestone optional formatted counts fre singleton | PASS |
| milestone optional formatted counts fre1 singleton | PASS |
| milestone optional formatted counts fre2 singleton | PASS |
| milestone tab preserves counts and missing categories sparse_cross | PASS |
| milestone optional formatted counts fre sparse_cross | PASS |
| milestone optional formatted counts fre1 sparse_cross | PASS |
| milestone optional formatted counts fre2 sparse_cross | PASS |
| milestone tab preserves counts and missing categories integers | PASS |
| milestone optional formatted counts fre integers | PASS |
| milestone optional formatted counts fre1 integers | PASS |
| milestone optional formatted counts fre2 integers | PASS |
| milestone tab preserves counts and missing categories doubles | PASS |
| milestone optional formatted counts fre doubles | PASS |
| milestone optional formatted counts fre1 doubles | PASS |
| milestone optional formatted counts fre2 doubles | PASS |
| milestone tab preserves counts and missing categories negative | PASS |
| milestone optional formatted counts fre negative | PASS |
| milestone optional formatted counts fre1 negative | PASS |
| milestone optional formatted counts fre2 negative | PASS |
| milestone tab preserves counts and missing categories logical | PASS |
| milestone optional formatted counts fre logical | PASS |
| milestone optional formatted counts fre1 logical | PASS |
| milestone optional formatted counts fre2 logical | PASS |
| milestone tab preserves counts and missing categories factor | PASS |
| milestone optional formatted counts fre factor | PASS |
| milestone optional formatted counts fre1 factor | PASS |
| milestone optional formatted counts fre2 factor | PASS |
| milestone tab preserves counts and missing categories ordered | PASS |
| milestone optional formatted counts fre ordered | PASS |
| milestone optional formatted counts fre1 ordered | PASS |
| milestone optional formatted counts fre2 ordered | PASS |
| milestone tab preserves counts and missing categories date | PASS |
| milestone optional formatted counts fre date | PASS |
| milestone optional formatted counts fre1 date | PASS |
| milestone optional formatted counts fre2 date | PASS |
| milestone tab preserves counts and missing categories missing_x | PASS |
| milestone optional formatted counts fre missing_x | PASS |
| milestone optional formatted counts fre1 missing_x | PASS |
| milestone optional formatted counts fre2 missing_x | PASS |
| milestone tab preserves counts and missing categories missing_y | PASS |
| milestone optional formatted counts fre missing_y | PASS |
| milestone optional formatted counts fre1 missing_y | PASS |
| milestone optional formatted counts fre2 missing_y | PASS |
| milestone tab preserves counts and missing categories both_missing | PASS |
| milestone optional formatted counts fre both_missing | PASS |
| milestone optional formatted counts fre1 both_missing | PASS |
| milestone optional formatted counts fre2 both_missing | PASS |
| milestone tab preserves counts and missing categories all_x_missing | PASS |
| milestone optional formatted counts fre all_x_missing | PASS |
| milestone optional formatted counts fre1 all_x_missing | PASS |
| milestone optional formatted counts fre2 all_x_missing | PASS |
| milestone tab preserves counts and missing categories all_y_missing | PASS |
| milestone optional formatted counts fre all_y_missing | PASS |
| milestone optional formatted counts fre1 all_y_missing | PASS |
| milestone optional formatted counts fre2 all_y_missing | PASS |
| milestone tab preserves counts and missing categories labelled | PASS |
| milestone optional formatted counts fre labelled | PASS |
| milestone optional formatted counts fre1 labelled | PASS |
| milestone optional formatted counts fre2 labelled | PASS |
| milestone tab preserves counts and missing categories unicode | PASS |
| milestone optional formatted counts fre unicode | PASS |
| milestone optional formatted counts fre1 unicode | PASS |
| milestone optional formatted counts fre2 unicode | PASS |
| milestone tab preserves counts and missing categories repeated_rows | PASS |
| milestone optional formatted counts fre repeated_rows | PASS |
| milestone optional formatted counts fre1 repeated_rows | PASS |
| milestone optional formatted counts fre2 repeated_rows | PASS |
| milestone tab preserves counts and missing categories one_category | PASS |
| milestone optional formatted counts fre one_category | PASS |
| milestone optional formatted counts fre1 one_category | PASS |
| milestone optional formatted counts fre2 one_category | PASS |
| milestone tab preserves counts and missing categories data_frame | PASS |
| milestone optional formatted counts fre data_frame | PASS |
| milestone optional formatted counts fre1 data_frame | PASS |
| milestone optional formatted counts fre2 data_frame | PASS |
| milestone review retains variable group keys tab1 | PASS |
| milestone review retains variable group keys fre1 | PASS |
| milestone review accepts general data frame expressions row_mean | PASS |
| milestone review accepts general data frame expressions row_sum | PASS |
| milestone review accepts general data frame expressions row_min | PASS |
| milestone review accepts general data frame expressions row_max | PASS |
| milestone review accepts general data frame expressions row_median | PASS |
| milestone review accepts general data frame expressions row_var | PASS |
| milestone review accepts general data frame expressions row_sd | PASS |
| milestone review accepts general data frame expressions row_unique | PASS |
| milestone review accepts general data frame expressions row_miss | PASS |
| milestone review accepts general data frame expressions row_non_miss | PASS |

## Actual output examples

Versioned demo reports in this directory record real console output for
tabulation, summaries, codebooks, row calculations, binning, selection, and
utilities. Historical reports are preserved; use INDEX.md for current links.
