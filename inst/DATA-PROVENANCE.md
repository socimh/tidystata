# Dataset provenance and distribution review

The shipped dataset objects are unchanged by the textbook-alignment work.
Preparation scripts under `data-raw/` in the source repository download pinned
inputs, check their hashes, and verify exact identity without overwriting data.
They are opt-in developer scripts, never installation or runtime steps.

## starwars

The object is identical to dplyr 1.1.3's `data/starwars.rda`:
https://raw.githubusercontent.com/tidyverse/dplyr/v1.1.3/data/starwars.rda

- MD5: `a1c7281e62ffbd808fda4e3496ca5387`.
- SHA-256: `f6cb50b862aba1487772c18d4405a40b335c9ee29ba2d7137db7fef870a61d8b`.
- Original statart (now tidystata) Git commit: `5d0b2566ee16fa4c5625b00464cf8bf57efaaa42`.
- Upstream preparation: https://github.com/tidyverse/dplyr/blob/v1.1.3/data-raw/starwars.R
- Intermediary: dplyr authors; upstream preparation acknowledges Megan Beckett's
  additional research on gender. Original source: SWAPI.

Relevant upstream notices are retained in THIRD-PARTY-NOTICES.md. Upstream
package licensing must not be interpreted as a blanket assertion about all
underlying film, website, or dataset rights.

## lifeexp

Verified reconstruction source:
https://www.stata-press.com/data/r17/lifeexp.dta

- MD5: `d1c20705b0842e4f3a4ba4b6d6ef38e6`.
- Imported with haven 2.5.5; reorder the three dataset notes as `c(3, 2, 1)`
  to preserve the existing object exactly.
- The original import release is unknown; Stata 17 is a verified reconstruction
  source rather than a claim about the historical import.
- Embedded source notes identify historical World Bank data.

## Publication gate

Reproducibility and redistribution authorization are separate questions. Before
publishing, record the applicable redistribution terms and any required notices
for both datasets. The reviewed Stata Press terms do not by themselves resolve
redistribution of this transformed dataset under tidystata's MIT declaration:
https://www.stata-press.com/terms-of-use/

The SWAPI description also acknowledges underlying Lucasfilm rights:
https://swapi.py4e.com/about

This record identifies unresolved evidence; it does not assert infringement or
grant permission. Do not remove, replace, or relicense datasets silently to
clear the gate. No third parties have been contacted.

## Follow-up source review (2026-10-18)

The retained lifeexp notes identify "The World Bank Group, Learning Modules"
and the historical URL http://www.worldbank.org/depweb/english/modules/basdata/bdata/.
This is more specific than a general World Development Indicators attribution.

The current [World Bank licensing page](https://datacatalog.worldbank.org/public-licenses)
describes CC BY 4.0 as the default for Bank-produced open datasets while identifying
exceptions and other licenses. That general policy does not establish the exact
terms for this historical Learning Modules selection or Stata's transformed file.
[Stata Press terms](https://www.stata-press.com/terms-of-use/) permit certain
informational document distribution with notices; they do not explicitly identify
this dataset transformation. [SWAPI's about page](https://swapi.py4e.com/about)
describes a BSD-licensed project and acknowledges underlying Lucasfilm rights.
The dplyr intermediary notice is preserved separately.

Publication remains on hold until the applicable terms are established and
required notices are recorded. The maintainer selected preservation of the
existing datasets while this gate is unresolved. No dataset replacement,
relicensing or third-party contact was undertaken.

## Validation-readiness evidence review (2026-10-18)

Rechecked the primary pages above and the
[release 17 dataset directory](https://www.stata-press.com/data/r17/d.html).
The directory acknowledges that some datasets have third-party permission;
it does not identify redistribution terms for this particular `lifeexp` object.
The [World Bank permissions page](https://www.worldbank.org/en/about/legal/permissions)
also directs use to applicable dataset-specific terms. General open-data policy
and an intermediary software license do not, by themselves, resolve the remaining
evidence questions for these exact objects.

To close the gate, retain an authoritative dataset-specific license record or
clarification covering the historical Learning Modules/Stata transformation and
the pinned dplyr/SWAPI/additional-research compilation, together with all required
notices. Both dataset dispositions remain pending evidence; the existing bytes
and notices are preserved. No third-party contact was made.
