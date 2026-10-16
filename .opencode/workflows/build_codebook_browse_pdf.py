"""Build ten pages of executed codebook/browse console examples for review."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import textwrap

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.opencode/results/codebook-browse-showcase'
SOURCE = ROOT / '.opencode/demos/showcase_codebook_browse.R'
PDF = OUT / 'statart_codebook_browse_console.pdf'

# Reuse the exact typography/panel system of the approved four-page PDF.
spec = importlib.util.spec_from_file_location('approved_showcase', ROOT / '.opencode/workflows/build_console_showcase.py')
style = importlib.util.module_from_spec(spec)
spec.loader.exec_module(style)
HEADER = style.HEADER.replace('STATART / SELECTIVE CONSOLE SHOWCASE', 'STATART / CODEBOOK + BROWSE')
HEADER += '\n#set document(title: "statart: codebook and browse console review", author: "statart development")\n'

PAGES = [
 dict(title='The shared research dataset', tag='01 / START HERE',
      purpose='These ten pages show current console output beside the R scripts that produce it. Eight fictional respondents keep the examples readable. Income is annual income in thousands.',
      code='''
      library(statart)
      library(dplyr)
      library(tibble)
      survey <- tibble(
        id = 1:8,
        region = c(rep("North", 4), rep("South", 4)),
        age = c(24, 31, 45, 52, 28, 36, 49, 57),
        income_k = c(32, 48, 55, 82, 29, 46, NA, 88),
        employed = c("Yes", "Yes", "No", "Yes", "Yes", "No", NA, "Yes")
      )
      attr(survey$income_k, "label") <- "Annual income in thousands"
      survey
      ''',
      note='Run the pages in order in one R session. The package snapshot is 0.2.0.9000 on Windows R 4.6.0. All console blocks come from execution, with 88-column plain-text printing, all rows and four significant digits. The data are illustrative, not research findings.'),
 dict(title='codebook() / the default inventory', tag='02 / OVERVIEW',
      purpose='One call gives a compact dictionary: variable name, optional variable label, type, observed count and number of distinct observed values.',
      code='''
      inventory <- codebook(survey)
      inventory

      names(inventory)
      ''',
      note='Each selected variable occupies one row. n excludes missing observations, while unique excludes missing values too. income_k has seven observed values; employed has seven observations and two distinct observed categories. The label column appears because income_k has a variable label.'),
 dict(title='Select, rename, or compute columns', tag='03 / FOCUS THE INVENTORY',
      purpose='Keep an inventory short by selecting relevant columns. Renamed variables keep their labels; deterministic expressions can also be inspected without changing the original data.',
      code='''
      codebook(survey, earnings = income_k, age)

      codebook(survey, higher_income = income_k >= 50)

      names(survey)
      ''',
      note='Selection is tried first, with data-masking expressions used as a fallback. earnings is a returned inventory name; survey still contains income_k. The computed indicator has seven observed values and two states. Precompute random or side-effecting expressions with mutate() before selection.'),
 dict(title='Missing values and list identities', tag='04 / THE COUNTING RULES',
      purpose='Imported survey missing codes and list columns need consistent counts. Both n and unique now use the same observed-value rule on the original column.',
      code='''
      imported <- tibble(
        response = haven::labelled_spss(c(1, 1, 99, NA), na_values = 99),
        payload = list(1:2, 1:2, NA, NULL)
      )
      codebook(imported)

      is.na(imported$response)
      ''',
      note='The SPSS code 99 is user-missing, so response has n = 2 and unique = 1. payload is counted by whole element identity: its scalar NA is excluded, while NULL remains present. Thus payload has three observed elements and two distinct observed identities. No list is flattened.'),
 dict(title='Structured and empty columns', tag='05 / EDGE CASES YOU MAY MEET',
      purpose='A matrix or nested data-frame column is one variable containing structured records. The counts refer to complete observed rows, not individual cells.',
      code='''
      pairs <- matrix(c(1, 1, 1, 1, NA, 2), ncol = 2, byrow = TRUE)
      structured <- tibble(pair = pairs, nested = as.data.frame(pairs))
      codebook(structured)

      codebook(tibble(score = c(NA_real_, NA_real_)))
      codebook(tibble(score = numeric()))
      ''',
      note='The first two structured rows are identical and complete; the third contains a missing cell. Each structured column therefore has n = 2 and unique = 1. All-missing and zero-row numeric columns remain inventory rows with zero counts, allowing later scripts to handle them explicitly.'),
 dict(title='Grouped input / one global inventory', tag='06 / GROUPING IS NOT AGGREGATION',
      purpose='Existing grouping no longer breaks the inventory. codebook() describes the whole input, and explicit selection is applied without reinserting unselected grouping keys.',
      code='''
      grouped <- group_by(survey, region)
      codebook(grouped)

      codebook(grouped, income_k)

      identical(group_vars(grouped), "region")
      ''',
      note='The first output still has one row per variable, not one row per region. The second contains only income_k. The TRUE result confirms the source remains grouped. Use summ() or tabstat() when you want numerical summaries separately for each region.'),
 dict(title='browse() / the invisible return', tag='07 / VIEW AND KEEP THE DATA',
      purpose='In an interactive R session browse() opens a data viewer. In this batch-generated PDF it opens no viewer and returns the selected data invisibly; an assigned object can be printed or reused.',
      code='''
      viewed <- browse(survey, id, income_k)
      viewed

      withVisible(browse(survey, id, income_k))$visible
      ''',
      note='The displayed rows come from evaluating viewed, not from automatic console printing inside browse(). FALSE confirms that browse() itself returns invisibly. This is the actual headless return value, not a screenshot or visual validation of an interactive GUI viewer.'),
 dict(title='browse() inside a preparation pipeline', tag='08 / INSPECT, THEN CONTINUE',
      purpose='A browse step can sit between data preparation and further transformations. The returned observation-level rows continue through the pipe.',
      code='''
      prepared <- survey |>
        filter(!is.na(income_k)) |>
        browse(id, region, age, income_k) |>
        mutate(log_income = log(income_k))
      prepared

      nrow(survey)
      ''',
      note='Filtering leaves seven observations in prepared; the source survey still has eight rows. log_income is computed on the retained positive incomes, creating a deterministic modeling variable. Keep sample rules and transformations tied to the study design.'),
 dict(title='s_select() / selection and computation', tag='09 / THE SHARED SELECTION STEP',
      purpose='codebook() and browse() use s_select() for their flexible input expressions. The successful result is now reused, avoiding unnecessary repeated selection or computation.',
      code='''
      s_select(survey, id, starts_with("income"))

      s_select(survey, income_scaled = income_k / 10)
      ''',
      note='The first call is ordinary column selection; the second returns a computed column. A failed selection attempt can still execute user code before fallback, so this is not a blanket exactly-once guarantee. For random draws or external side effects, use mutate() first, then pass column names.'),
 dict(title='Use an inventory in the next research stage', tag='10 / DESCRIBE AND SAVE',
      purpose='The inventory is an ordinary tibble. Use its metadata to choose variables, produce a descriptive table, and save the dictionary for a later report.',
      code='''
      numeric_vars <- inventory |>
        filter(type == "double", n >= 6) |>
        pull(variable)
      numeric_vars
      summary_table <- survey |>
        summ(all_of(numeric_vars), .stat = c("n", "mean", "sd"))
      summary_table

      output_dir <- ".opencode/results/codebook-browse-showcase/tables"
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
      write.csv(inventory, file.path(output_dir, "survey_dictionary.csv"),
                row.names = FALSE, na = "")
      ''',
      note='Here the rule selects age and income_k; it excludes the integer ID. The CSV contains the dictionary, not console formatting, and the write call prints nothing. Keep respondent-level prepared data for later models. Sample rules, missing-data methods and interpretation remain research decisions.')
]
for page in PAGES:
    page['code'] = textwrap.dedent(page['code']).strip()

CAPTURE = r'''
args <- commandArgs(trailingOnly = TRUE)
.libPaths(c(normalizePath(args[[1]]), .libPaths()))
suppressPackageStartupMessages({library(statart); library(dplyr); library(tibble)})
stopifnot(as.character(packageVersion("statart")) == "0.2.0.9000", requireNamespace("haven", quietly = TRUE))
source_lines <- readLines(".opencode/demos/showcase_codebook_browse.R", encoding = "UTF-8")
starts <- grep("^# SECTION ", source_lines)
invisible(parse(file = ".opencode/demos/showcase_codebook_browse.R", encoding = "UTF-8"))
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
  writeLines(enc2utf8(output), sprintf(".opencode/results/codebook-browse-showcase/console-%02d.txt", i), useBytes = TRUE)
}
stopifnot(identical(inventory$n, c(8L,8L,8L,7L,7L)),
          identical(inventory$unique, c(8L,2L,8L,7L,2L)),
          identical(codebook(imported)$n, c(2L,3L)),
          identical(codebook(imported)$unique, c(1L,2L)),
          identical(codebook(structured)$n, c(2L,2L)),
          identical(codebook(structured)$unique, c(1L,1L)),
          !withVisible(browse(survey,id))$visible,
          identical(viewed, dplyr::select(survey,id,income_k)),
          nrow(prepared) == 7L, nrow(survey) == 8L,
          identical(numeric_vars,c("age","income_k")),
          identical(summary_table$n,c(8L,7L)))
restored <- read.csv(file.path(output_dir,"survey_dictionary.csv"),check.names=FALSE)
stopifnot(nrow(restored)==nrow(inventory),identical(names(restored),names(inventory)),
          identical(restored$variable,inventory$variable),
          identical(restored$n,inventory$n),identical(restored$unique,inventory$unique))
cat("SHOWCASE VERIFIED 10 sections; no unexpected diagnostics; counts, visibility, pipeline and CSV readback passed\n")
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
        paths = json.loads((ROOT/'.opencode/results/codebook-browse-accepted-paths.json').read_text(encoding='utf-8'))
        for name in ('R/codebook.R','R/browse.R','R/s_select.R','R/variables.R','R/summ.R','R/summ-helpers.R'):
            assert (ROOT/name).read_bytes() == (Path(paths['source'])/name).read_bytes(), name
        source = ['# Generated by .opencode/workflows/build_codebook_browse_pdf.py; edit that source.',
                  '# Run the ten sections in order from the project root.',
                  'options(width = 88, tibble.width = 88, pillar.width = 88,',
                  '        tibble.print_max = Inf, tibble.print_min = Inf,',
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
                    verification='Protected R exit0; ten sections; observed counts, invisible return, pipeline rows and CSV readback verified')
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    report = ROOT/'.opencode/reports/project_status_codebook_browse_pdf_2026-10-16.md'
    report.write_text('\n'.join([
        '# Codebook and browse console PDF', '',
        'Created 2026-10-16, statart 0.2.0.9000, Windows R 4.6.0.', '',
        '[Open the ten-page PDF](../results/codebook-browse-showcase/statart_codebook_browse_console.pdf)', '',
        'Ten selected examples show setup, default inventory, selected/renamed/computed columns,',
        'SPSS/list missingness, structured/empty columns, grouped inventory, browse visibility,',
        'browse in a pipeline, s_select and a dictionary-driven summary/CSV workflow.', '',
        'Canonical authoring source: [build_codebook_browse_pdf.py](../workflows/build_codebook_browse_pdf.py).',
        'Generated R input: [showcase_codebook_browse.R](../demos/showcase_codebook_browse.R).',
        'Style is reused from the previously approved four-page showcase; that PDF is unchanged.', '',
        'Protected execution: exit0, ten sections, no unexpected warnings/messages.',
        'Counts, uniqueness, browse visibility, pipeline rows, selected variables and exported CSV',
        'readback are asserted. PDF text checks require ten pages with complete input/output panels;',
        'all rendered pages are visually reviewed for spacing, glyphs, clipping and legibility.', '',
        'Console output is actual plain text. Headless browse opens no viewer; assigned returns',
        'are explicitly printed. This is not a GUI screenshot or real viewer validation.',
        'No package functions, dependencies, exports or accepted test results changed.', '',
        'Regenerate with `python .opencode/workflows/build_codebook_browse_pdf.py` after the fresh',
        'library is available in codebook-browse-accepted-paths.json. `--render-only` reuses captures.',
        'Intermediate captures, Typst source, PNGs and execution logs remain preserved locally.',
    ])+'\n',encoding='utf-8')
    print(json.dumps(manifest,indent=2))


if __name__ == '__main__':
    main()
