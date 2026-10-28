# Look up Stata text from the editor or clipboard

Look up one Stata command using the same catalogue and variable
customization as
[`findit()`](https://socimh.github.io/tidystata/reference/findit.md).
The result is printed in the console. Source text and clipboard contents
are preserved; no command or returned example is executed.

## Usage

``` r
findit_selection()

findit_clip()
```

## Value

The [`findit()`](https://socimh.github.io/tidystata/reference/findit.md)
result, invisibly, after printing it once.

## Details

`findit_selection()` reads highlighted text in the source editor. It is
also registered as the **Find Stata equivalent** addin. It requires the
optional rstudioapi package and an editor providing its source-selection
API, such as RStudio or a compatible Positron session.

`findit_clip()` reads text copied to the clipboard, for example from a
do-file. It requires the optional clipr package and access to a text
clipboard.

## See also

[`findit()`](https://socimh.github.io/tidystata/reference/findit.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Highlight tab sex region, row in the source editor, then run:
findit_selection()

# Copy tab sex region, row to the clipboard, then run:
findit_clip()
} # }
```
