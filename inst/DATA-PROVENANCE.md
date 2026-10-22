# Dataset provenance

tidystata ships one dataset, `lifeexp`. Examples and tests that need a
character-heavy dataset use `dplyr::starwars` from dplyr (>= 1.1.4) instead of
a bundled copy.

## lifeexp

Source: World Bank, World Development Indicators (WDI),
https://datacatalog.worldbank.org/search/dataset/0037712, licensed under the
Creative Commons Attribution 4.0 International license (CC BY 4.0),
https://creativecommons.org/licenses/by/4.0/. The World Bank catalog lists
CC BY 4.0 as the WDI license and as its default for Bank-produced datasets:
https://datacatalog.worldbank.org/public-licenses

- Indicators: `SP.POP.GROW` (popgrowth), `SP.DYN.LE00.IN` (lexp) and
  `NY.GNP.PCAP.CD` (gnppc, GNI per capita, Atlas method) for 1998, and
  `SH.H2O.SMDW.ZS` (safewater, safely managed drinking water) for 2000, the
  earliest year WDI reports it.
- Retrieved from the World Bank API on 2026-10-21. The retrieved values are
  kept in the source repository as `data-raw/lifeexp-wdi.csv`;
  `data-raw/lifeexp.R` rebuilds `data/lifeexp.rda` from that snapshot.
- Changes from the source: values are rounded (popgrowth to one decimal, the
  others to integers); variable labels, value labels and a three-region coding
  are added. Country names follow WDI, and Serbia (`SRB`) stands in for the
  Federal Republic of Yugoslavia.

The countries, region coding, variable names and labels follow the layout of
Stata's `lifeexp.dta` example so that Stata users recognize it. No values are
taken from that file.

## History

Earlier development versions (as statart) shipped `lifeexp` as imported
from Stata's `lifeexp.dta`, whose embedded notes cite the World Bank Learning
Modules, and a copy of `starwars` from dplyr 1.1.3. Their redistribution terms
could not be established, so 0.3.0 rebuilds `lifeexp` from openly licensed WDI
data and drops the `starwars` copy.
