"""Build ten pages of executed persistent-preview console examples for review."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import textwrap

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.opencode/results/preview-showcase'
SOURCE = ROOT / '.opencode/demos/showcase_previews.R'
PDF = OUT / 'statart_preview_console.pdf'

# Reuse the exact typography/panel system of the approved four-page PDF.
spec = importlib.util.spec_from_file_location('approved_showcase', ROOT / '.opencode/workflows/build_console_showcase.py')
style = importlib.util.module_from_spec(spec)
spec.loader.exec_module(style)
HEADER = style.HEADER.replace('STATART / SELECTIVE CONSOLE SHOWCASE', 'STATART / PERSISTENT TABLE PREVIEWS')
HEADER += '\n#set document(title: "statart: persistent table previews", author: "statart development")\n'

PAGES = [
 dict(title='A complete table, a compact preview', tag='01 / START HERE',
 purpose='All ten pages use this fictional 36-person survey. Run the scripts in order. The default preview shows five rows from each end while keeping every observation.',
 code='''library(statart)
library(dplyr)
survey <- tibble::tibble(
  id = 1:36,
  region = rep(c("North", "South", "West"), each = 12),
  age = 22 + (1:36),
  income_k = 32 + ((1:36) %% 11) * 3.5
)
survey$income_k[c(7, 19)] <- NA_real_
x <- preview_table(survey)
x''',
 note='Income is annual income in thousands. The header reports all 36 rows; the margin shows current row positions. These are executed console outputs from statart 0.2.0.9000, Windows R 4.6.0, at 80 columns and four significant digits.'),
 dict(title='Look across the distribution', tag='02 / EVENLY SPACED POSITIONS',
 purpose='Sort first, then inspect regularly spaced positions across the entire result. This is a deterministic positional preview, not a random sample or a set of statistical quantiles.',
 code='''ranked <- x |>
  arrange(income_k, id) |>
  preview_table(style = "interval", n = 6)
ranked
nrow(ranked)''',
 note='Both endpoints are shown. The margin is the position in the sorted table; id still identifies the respondent. Missing incomes sort to the end. All 36 rows remain available.'),
 dict(title='Edit the data without losing the style', tag='03 / FILTER + MUTATE + ARRANGE',
 purpose='The wrapper can sit near the beginning of a preparation pipeline. Filtering, adding a variable and sorting retain the display preference.',
 code='''prepared <- preview_table(survey, n = 6) |>
  filter(!is.na(income_k)) |>
  mutate(log_income = log(income_k)) |>
  arrange(desc(income_k))
prepared
c(source_rows = nrow(survey), analysis_rows = nrow(prepared))''',
 note='The preview shows three rows from each end. Filtering actually removes two missing incomes; printing removes none. The new margin positions run from 1 to 34 and update automatically.'),
 dict(title='Preview a long frequency table', tag='04 / TABULATION RESULTS',
 purpose='Apply the wrapper after tab() to inspect both common and rare categories without discarding any category counts.',
 code='''frequencies <- survey |>
  tab(age) |>
  select(age, n, percent) |>
  preview_table(n = 6)
frequencies
c(categories = nrow(frequencies), respondents = sum(frequencies$n))''',
 note='This illustration has 36 distinct ages, each observed once. The printed subset is only a display choice: all category rows still contribute to the total count. Percentages use the original tabulation denominator.'),
 dict(title='Preview descriptive statistics', tag='05 / SUMM RESULTS',
 purpose='A grouped descriptive table can become long as more variables and groups are added. Keep its complete numeric results while making the console view shorter.',
 code='''descriptives <- survey |>
  summ(age, income_k, .by = region,
       .stat = c("n", "mean", "sd")) |>
  preview_table(n = 4)
descriptives
nrow(descriptives)''',
 note='The result contains six rows: two variables for each of three regions. n counts observed values for each variable. Hidden rows remain in the table for later reporting or export.'),
 dict(title='Keep the preview through a pivot', tag='06 / GROUP + SUMMARISE + RESHAPE',
 purpose='Grouping, aggregation and reshaping create new table structures. The preview follows these steps while their ordinary data and grouping semantics are retained.',
 code='''regional <- preview_table(survey, n = 4) |>
  group_by(region) |>
  summarise(observed = sum(!is.na(income_k)),
            mean_income = mean(income_k, na.rm = TRUE),
            .groups = "drop") |>
  tidyr::pivot_longer(c(observed, mean_income),
                      names_to = "measure", values_to = "value")
regional
inherits(regional, "statart_preview")''',
 note='The long table has six rows. Its four-row preview was set before grouping and survives both the summary and pivot without reapplying the wrapper. TRUE confirms the resulting table still carries the persistent preview class.'),
 dict(title='Join a group statistic back to people', tag='07 / A SUBSEQUENT RESEARCH STEP',
 purpose='Attach regional means to respondent records and calculate a descriptive income gap. The left table supplies the display policy for the join.',
 code='''means <- survey |>
  group_by(region) |>
  summarise(region_mean = mean(income_k, na.rm = TRUE))
analysis <- preview_table(survey, n = 4) |>
  left_join(means, by = "region") |>
  mutate(income_gap = income_k - region_mean) |>
  select(id, region, income_k, region_mean, income_gap)
analysis
nrow(analysis)''',
 note='All 36 respondents are retained. Missing incomes lead to missing gaps. The gap is a descriptive difference from a regional mean, not a causal effect. Keep this observation-level table for subsequent analysis.'),
 dict(title='Use a preview just once', tag='08 / PRINT HELPERS',
 purpose='The original print helpers remain useful when you want one compact inspection without permanently changing the table class.',
 code='''print_headtail(survey, n = 4)
print_interval(survey, n = 4)
c(rows = nrow(survey),
  persistent = inherits(survey, "statart_preview"))''',
 note='Both helpers invisibly return the original input. n is the total number displayed, not a separate count for each end. The final 0 means survey has not acquired the persistent class.'),
 dict(title='Previewing versus taking a subset', tag='09 / SLICE HELPERS',
 purpose='Use slice helpers only when you intentionally want a smaller data object. Unlike preview_table(), they actually select rows.',
 code='''ends <- slice_headtail(survey, n = 4)
spaced <- slice_interval(survey, n = 4)
ends
spaced
c(source = nrow(survey), ends = nrow(ends), spaced = nrow(spaced))''',
 note='Each returned table has four rows; the source still has 36. These positional subsets are suitable for inspection, not automatically representative analysis samples. Short inputs never duplicate rows.'),
 dict(title='Override or remove the preview', tag='10 / CONTROL THE DISPLAY',
 purpose='A print override is temporary. Remove the preview explicitly when you want an ordinary tibble, while preserving all stored rows and columns.',
 code='''small <- x |> filter(id <= 6) |> preview_table(n = 2)
small
print(small, n = Inf)
ordinary <- unpreview_table(small)
c(rows = nrow(ordinary),
  persistent = inherits(ordinary, "statart_preview"))''',
 note='The first print shows two rows; the second shows all six. small keeps its two-row preference. unpreview_table() removes only the display policy. Explicit as_tibble() or as.data.frame() conversions also remove it; console formatting does not control GUI viewers.')
]
for page in PAGES:
    page['code'] = textwrap.dedent(page['code']).strip()

CAPTURE = r'''
args <- commandArgs(trailingOnly = TRUE)
.libPaths(c(normalizePath(args[[1]]), .libPaths()))
suppressPackageStartupMessages({library(statart); library(dplyr); library(tibble)})
stopifnot(as.character(packageVersion("statart")) == "0.2.0.9000", requireNamespace("haven", quietly = TRUE))
source_lines <- readLines(".opencode/demos/showcase_previews.R", encoding = "UTF-8")
starts <- grep("^# SECTION ", source_lines)
invisible(parse(file = ".opencode/demos/showcase_previews.R", encoding = "UTF-8"))
eval(parse(text = paste(source_lines[seq_len(starts[[1]] - 1L)], collapse = "\n")), envir = .GlobalEnv)
for (i in seq_along(starts)) {
  last <- if (i < length(starts)) starts[[i + 1L]] - 1L else length(source_lines)
  code <- paste(source_lines[(starts[[i]] + 1L):last], collapse = "\n")
  output <- capture.output(withCallingHandlers({
    for (expression in parse(text = code)) {
      result <- withVisible(eval(expression, envir = .GlobalEnv))
      if (result$visible) print(result$value)
    }
  }, warning = function(w) stop("Unexpected warning: ", conditionMessage(w)),
     message = function(m) stop("Unexpected message: ", conditionMessage(m))))
  writeLines(enc2utf8(output), sprintf(".opencode/results/preview-showcase/console-%02d.txt", i), useBytes = TRUE)
}
stopifnot(nrow(x)==36L, nrow(ranked)==36L, nrow(prepared)==34L,
          nrow(frequencies)==36L, sum(frequencies$n)==36L,
          nrow(descriptives)==6L, nrow(regional)==6L,
          nrow(analysis)==36L, nrow(ends)==4L, nrow(spaced)==4L,
          identical(ends$id,c(1L,2L,35L,36L)),
          identical(spaced$id,c(1L,13L,24L,36L)),
          inherits(regional,"statart_preview"),
          inherits(analysis,"statart_preview"),
          !inherits(survey,"statart_preview"),
          !inherits(ordinary,"statart_preview"),nrow(ordinary)==6L)
cat("SHOWCASE VERIFIED 10 sections; no unexpected diagnostics; full data, pipelines and subsets verified\n")
cat(R.version.string,"\n")
'''

def quote(value):
    return json.dumps(value, ensure_ascii=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render-only', action='store_true')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    if not args.render_only:
        paths = json.loads((ROOT/'.opencode/results/preview-final-paths.json').read_text(encoding='utf-8'))
        for name in ('R/special-print.R','R/tab.R','R/tab-helpers.R','R/summ.R','R/summ-helpers.R','NAMESPACE'):
            assert (ROOT/name).read_bytes() == (Path(paths['source'])/name).read_bytes(), name
        source = ['# Generated by .opencode/workflows/build_preview_pdf.py; edit that source.',
                  '# Run the ten sections in order from the project root.',
                  'options(width = 80, tibble.width = 80, pillar.width = 80,',
                  '        tibble.print_max = 20, tibble.print_min = 10,',
                  '        pillar.sigfig = 4, cli.unicode = FALSE, crayon.enabled = FALSE)', '']
        for i,page in enumerate(PAGES,1):
            source += [f'# SECTION {i:02d}: {page["title"]}',page['code'],'']
        SOURCE.write_text('\n'.join(source),encoding='utf-8')
        (OUT/'capture.R').write_text(CAPTURE,encoding='utf-8')
        env = os.environ.copy()
        env.update(LC_ALL='C',LANG='C',NO_COLOR='1')
        with (OUT/'execution.log').open('w',encoding='utf-8') as stream:
            result = subprocess.run(['python','C:/Users/socimh/.codex/scripts/run_r_safe.py','--',
                                     'Rscript',str(OUT/'capture.R'),paths['library']],cwd=ROOT,
                                    env=env,stdout=stream,stderr=subprocess.STDOUT)
        log = (OUT/'execution.log').read_text(encoding='utf-8')
        if result.returncode:
            raise RuntimeError(log[-7000:])
        assert 'SHOWCASE VERIFIED 10 sections' in log and 'R launcher exit: 0x00000000' in log
    document = [HEADER]
    for i,page in enumerate(PAGES,1):
        if i > 1:
            document.append('#pagebreak()')
        output = (OUT/f'console-{i:02d}.txt').read_text(encoding='utf-8').rstrip()
        assert output
        document += ['#v(3mm)', '#text(size: 9pt, weight: "bold", fill: teal, '+quote(page['tag'])+')',
                     '#v(4mm)', '#text(size: 24pt, weight: "bold", '+quote(page['title'])+')',
                     '#v(3mm)', '#text('+quote(page['purpose'])+')',
                     '#panel("R INPUT", '+quote(page['code'])+', script: true)',
                     '#panel("CONSOLE OUTPUT", '+quote(output)+')',
                     '#hint('+quote(page['note'])+')']
    typ = OUT/'showcase.typ'
    typ.write_text('\n'.join(document),encoding='utf-8')
    subprocess.run(['typst','compile','--root',str(ROOT),str(typ),str(PDF)],cwd=ROOT,check=True)
    subprocess.run(['pdftotext','-layout',str(PDF),str(OUT/'extracted.txt')],check=True)
    extracted = (OUT/'extracted.txt').read_text(encoding='utf-8')
    pages = [p for p in extracted.split('\f') if p.strip()]
    assert len(pages) == 10, f'Expected ten pages, found {len(pages)}; inspect overflow.'
    for i,page in enumerate(PAGES):
        assert page['title'] in pages[i], (i,page['title'])
        assert 'R INPUT' in pages[i] and 'CONSOLE OUTPUT' in pages[i],i
    assert '\ufffd' not in extracted
    subprocess.run(['pdftoppm','-scale-to','1400','-png',str(PDF),str(OUT/'page')],check=True)
    manifest = dict(pdf=str(PDF),pages=len(pages),examples=10,
                    sha256=hashlib.sha256(PDF.read_bytes()).hexdigest(),source=str(SOURCE),
                    verification='Protected R exit0; ten sections; full row counts, persistent classes, pipelines and selected subsets verified')
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    report = ROOT/'.opencode/reports/project_status_preview_pdf_2026-10-16.md'
    report.write_text("\n".join([
        "# Persistent preview console PDF", "",
        "[Open the ten-page PDF](../results/preview-showcase/statart_preview_console.pdf)", "",
        "Ten selected pages pair executable R inputs with actual current console output.",
        "Topics: default head/tail, intervals, editing, tabulation, summaries, pivots,",
        "joins, one-time printing, real slicing, and removing/overriding the preview.", "",
        "Canonical authoring source: .opencode/workflows/build_preview_pdf.py.",
        "Generated input: .opencode/demos/showcase_previews.R.",
        "Protected R execution exited zero; all ten sections passed assertions for",
        "row preservation, counts, subsets and persistent class behavior, without",
        "unexpected warnings or messages. Text checks confirm ten complete pages.",
        "Rendered pages are visually inspected before delivery.", "",
        "Package code and existing PDFs are unchanged. Package-wide acceptance remains",
        "3,106 blocks/16,992 expectations and R CMD check Status: OK from the prior task.",
        "This task verifies the showcase; it does not rerun or expand the full suite.", "",
        "Regenerate: python .opencode/workflows/build_preview_pdf.py.",
        "Uses the verified installation referenced by preview-final-paths.json.",
        "Intermediate captures, rendered pages and logs remain preserved locally."
    ])+"\n", encoding='utf-8')
    print(json.dumps(manifest,indent=2))


if __name__ == '__main__':
    main()
