# Maintaining the lookup reference

`legacy.csv` and `legacy-provenance.csv` preserve the original examples and
their stable IDs. `*-reference.json` files are the authoritative sources for
new examples: code, bilingual explanations, variable roles, source references,
fixture setup and independently stated checks live together. `functions.csv`
maintains the R function/package dictionary.
Keep its English and Chinese descriptions current for every exported tidystata
function, including helpers without a direct Stata equivalent. The re-exported
pipe is excluded. Refresh affected example notes when a function contract changes.

Run `python data-raw/findit/build-reference.py` from the repository root to
regenerate the distributed CSVs, additional R template annotations and execution
fixtures. Format the generated R annotations with the pinned Air formatter described in
CONTRIBUTING.md. Never edit those generated additions directly. New IDs derive
from command, Stata syntax and R code. Existing records retain their explicit
`id` when code or explanations are corrected, so links and book anchors remain
stable. Different established IDs may share corrected code.

Run the exact generated snippets through the protected launcher:

```powershell
python C:/Users/socimh/.codex/scripts/run_r_safe.py -- Rscript data-raw/findit/verify-reference.R . .opencode/results/findit-reference-execution.csv
```

This execution check needs the packages explicitly referenced by the examples.
It never installs or attaches them. Missing prerequisites, errors and unexpected
warnings fail validation. The one-time fwildclusterboot RNG compatibility notice
is matched explicitly, recorded separately and explained in its example.
Each row runs with its own fixture, temporary working
directory and PDF device, so file and graphics examples cannot overwrite project
outputs. Temporary results are retained under the operating system's temp area.

Execution establishes that an R example and its fixture check work. It does not
establish Stata numerical parity. Qualify differences in estimators, defaults,
weights, missingness, interval boundaries and model context explicitly. Cite
official Stata and R documentation or original package authors; independently
write examples and explanations rather than importing third-party cheat sheets.

Counts distinguish command families, functions, operators and prefixes. Options,
subcommands, abbreviations and alternative R implementations do not inflate the
command-family count. Earlier `legacy` entries remain distinguishable from
new examples whose exact code is checked by the execution corpus.

The `package` column names the primary package for the mapping, rather than
every dependency used in its R expression. Namespace-qualified calls identify
additional packages, such as `lmtest` in a `coeftest()` wrapper; consult the R
function dictionary for their descriptions.
