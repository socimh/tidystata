# Function: containers()

**Version:** 0.3.0 | **Generated:** 2026-10-21 20:14:19 | **Status:** PASS

## Example: container preservation and downstream operations

```text
Installed tidystata: 0.3.0
Container checks (list functions show their first table):
data.frame tab data.frame PASS
data.frame tab1 data.frame PASS
data.frame tab2 data.frame PASS
data.frame fre data.frame PASS
data.frame fre1 data.frame PASS
data.frame fre2 data.frame PASS
data.frame summ data.frame PASS
data.frame tabstat data.frame PASS
data.frame codebook data.frame PASS
data.frame ds_as_column data.frame PASS
data.frame ds_as_column data.frame PASS
data.frame variables data.frame PASS
data.frame variables_search data.frame PASS
data.frame slice_headtail data.frame PASS
data.frame slice_interval data.frame PASS
data.frame preview_round_trip data.frame PASS
tibble tab tbl_df/tbl/data.frame PASS
tibble tab1 tbl_df/tbl/data.frame PASS
tibble tab2 tbl_df/tbl/data.frame PASS
tibble fre tbl_df/tbl/data.frame PASS
tibble fre1 tbl_df/tbl/data.frame PASS
tibble fre2 tbl_df/tbl/data.frame PASS
tibble summ tbl_df/tbl/data.frame PASS
tibble tabstat tbl_df/tbl/data.frame PASS
tibble codebook tbl_df/tbl/data.frame PASS
tibble ds_as_column tbl_df/tbl/data.frame PASS
tibble ds_as_column tbl_df/tbl/data.frame PASS
tibble variables tbl_df/tbl/data.frame PASS
tibble variables_search tbl_df/tbl/data.frame PASS
tibble slice_headtail tbl_df/tbl/data.frame PASS
tibble slice_interval tbl_df/tbl/data.frame PASS
tibble preview_round_trip tbl_df/tbl/data.frame PASS
data.table tab data.table/data.frame PASS
data.table tab1 data.table/data.frame PASS
data.table tab2 data.table/data.frame PASS
data.table fre data.table/data.frame PASS
data.table fre1 data.table/data.frame PASS
data.table fre2 data.table/data.frame PASS
data.table summ data.table/data.frame PASS
data.table tabstat data.table/data.frame PASS
data.table codebook data.table/data.frame PASS
data.table ds_as_column data.table/data.frame PASS
data.table ds_as_column data.table/data.frame PASS
data.table variables data.table/data.frame PASS
data.table variables_search data.table/data.frame PASS
data.table slice_headtail data.table/data.frame PASS
data.table slice_interval data.table/data.frame PASS
data.table preview_round_trip data.table/data.frame PASS

Counts and downstream mutation:
  g n  percent       cum    valid valid_cum twice
1 a 2 66.66667  66.66667 66.66667  66.66667     4
2 b 1 33.33333 100.00000 33.33333 100.00000     2

Summary:
  type n unique min mean sd max
1  dbl 3      3   1    3  2   5

Explicit tibble override:
[1] "tbl_df"     "tbl"        "data.frame"

Base-frame preview and unchanged round trip:
[1] "tidystata_preview" "data.frame"
# Description: df [3 x 2]
  g         x
  <chr> <dbl>
1 a         1
3 b         5
# ... 1 rows omitted in the middle; use print(x, n = Inf) to show all rows.

Native data.table preview mutation leaves original unchanged:
# Description: dt [2 x 2]
  g     total
  <chr> <dbl>
1 a         8
2 b        10

All container and demonstration assertions passed.
```
