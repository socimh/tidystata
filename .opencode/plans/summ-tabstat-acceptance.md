# Summary acceptance review

Approved scope: review summ and tabstat one by one, repair confirmed defects,
and record function-level evidence before local release-candidate sign-off.

- [x] Read source, contracts, previous evidence and current Git state.
- [x] Independently reproduce grouping-key collisions, grouped .by override,
  empty .name behavior, reserved measured-column names, compact datetime errors,
  and SPSS user-missing contamination; add failing public-API tests.
- [x] Confirm maintainer policy: .keep_all retains character/list counts and
  unique values, with numeric statistics NA, including character-only data.
- [x] Apply targeted fixes without changing moment conventions or exports.
- [x] Verify new regressions and retained summary tests; independently review.
- [x] Update source help, regenerate documentation and actual-output examples.
- [x] Run fresh protected full-suite/build/check and inspect results.
- [x] Update current status/readiness notes, evidence/report index and commit locally.

Constraints: work in the requested folder on the existing development branch;
no push, merge, release, dependency expansion or unrelated failure repairs.
Original artifacts are preserved. All R execution uses the protected launcher.

Readiness means locally accepted on Windows R 4.6.0; minimum R and other
platform checks remain package publication gates. Preserve existing skewness
and excess-kurtosis formulas and document them; do not claim Stata equivalence.
Calendar locations remain formatted strings (datetimes UTC, minute precision).
