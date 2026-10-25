"""Deterministic Stata highlighting for the rendered book.

Pandoc's Stata grammar colours words from a fixed keyword list, so variable
names such as ``y`` or ``x2`` look like functions or commands while many real
commands stay plain. This pass re-tokenises each Stata line from its text and
emits the same span classes for the same role on every page and edition:
``kw`` command, ``fu`` option or function, ``qu`` qualifier, ``st`` string,
``mc`` macro, ``dv`` number, ``co`` comment. The text itself never changes.
"""
import html
import re

# Prefixes that end in a colon and introduce a new command.
COLON_PREFIXES = {
    "by", "bys", "bysort", "svy", "mi", "xi", "statsby", "bootstrap", "bs",
    "jackknife", "permute", "rolling", "simulate", "nestreg", "stepwise", "sw",
    "fp", "mfp", "frame", "version", "eststo", "estpost", "quietly", "qui",
    "noisily", "noi", "capture", "cap", "capt", "bayes", "fmm", "collect",
    "timer", "python", "mata", "sem", "gsem",
}
# Prefixes that need no colon.
BARE_PREFIXES = {"quietly", "qui", "noisily", "noi", "capture", "cap", "capt"}
# Commands whose next word names a subcommand.
SUBCOMMANDS = {
    "estat", "graph", "twoway", "tw", "mi", "label", "lab", "char", "matrix", "mat",
    "file", "net", "ssc", "ado", "ereturn", "return", "sreturn", "collect", "frame",
    "frames", "import", "export", "duplicates", "notes", "misstable", "set", "query",
    "putdocx", "putpdf", "putexcel", "tsfilter", "tssmooth", "fvset", "cluster", "ml",
    "odbc", "macro", "program", "log", "cmdlog", "snapshot", "estimates", "est",
    "constraint", "vl", "spmatrix", "sts", "power", "irt", "bayesstats", "bayestest",
    "teffects", "stteffects", "meta", "lasso", "datasignature", "unicode", "window",
    "creturn", "ssd", "icd10", "icd9", "mvtest",
}
QUALIFIERS = {"if", "in", "using"}
TOKEN = re.compile(
    r"(?P<space>\s+)|(?P<cstr>`\".*?\"')|(?P<str>\"[^\"]*\"?)|(?P<macro>`[^']*'?|\$\{[^}]*\}|\$\w+)"
    r"|(?P<num>(?<![\w.])(?:\d+\.?\d*|\.\d+)(?![\w]))|(?P<word>[A-Za-z_]\w*)|(?P<other>.)",
)


def stata_spans(lines):
    """Return each line as a list of (class or None, text) pieces."""
    out, block, continued = [], False, False
    for line in lines:
        pieces, i, depth = [], 0, 0
        command, sub, options, colon, twoway, layer = not continued, False, False, False, False, False
        continued = False
        stripped = line.lstrip()
        if not block and command and stripped.startswith("*"):
            out.append([("co", line)] if line else [])
            continue
        while i < len(line):
            if block:
                end = line.find("*/", i)
                stop = len(line) if end < 0 else end + 2
                pieces.append(("co", line[i:stop]))
                block, i = end < 0, stop
                continue
            if line.startswith("///", i):
                pieces.append(("co", line[i:]))
                continued = True
                break
            if line.startswith("//", i) and (i == 0 or line[i - 1].isspace()):
                pieces.append(("co", line[i:]))
                break
            if line.startswith("/*", i):
                block = True
                continue
            m = TOKEN.match(line, i)
            kind, text = m.lastgroup, m.group()
            i = m.end()
            if kind == "space":
                pieces.append((None, text))
            elif kind in ("cstr", "str"):
                pieces.append(("st", text))
            elif kind == "macro":
                pieces.append(("mc", text))
            elif kind == "num":
                pieces.append(("dv", text))
            elif kind == "word":
                call = line.startswith("(", i)
                if command:
                    pieces.append(("kw", text))
                    command = text in BARE_PREFIXES
                    colon = colon or text in COLON_PREFIXES
                    sub = text in SUBCOMMANDS
                    twoway = twoway or text in ("twoway", "tw")
                elif sub and not call and text not in QUALIFIERS:
                    # A subcommand: ``estat hettest``, ``graph twoway scatter``.
                    pieces.append(("kw", text))
                    sub = text in ("twoway", "tw")
                    twoway = twoway or sub
                elif layer and not call:
                    # A plot type opening a twoway layer.
                    pieces.append(("kw", text))
                elif call or (options and depth == 0):
                    pieces.append(("fu", text))
                elif text in QUALIFIERS and depth == 0:
                    pieces.append(("qu", text))
                else:
                    pieces.append((None, text))
                layer = False
                if pieces[-1][0] != "kw":
                    sub = False
            else:
                if text == "|" and line.startswith("|", i):
                    text, i = "||", i + 1
                opens_layer = twoway and (text == "||" or (text == "(" and (not pieces or pieces[-1][0] != "fu")))
                pieces.append((None, text))
                layer = opens_layer
                sub = False
                if text == "(":
                    depth += 1
                elif text == ")":
                    depth = max(depth - 1, 0)
                elif text == "," and depth == 0:
                    options = True
                elif text == ":" and depth == 0 and colon:
                    command, options, colon = True, False, False
                elif text == "||":
                    options = False
        out.append(pieces)
    return out


LINE = re.compile(r'(<span id="[^"]+">(?:<a [^>]*></a>)?)(.*)(</span>)\Z', re.S)
BLOCK = re.compile(r'(<pre class="sourceCode stata[^"]*"[^>]*><code[^>]*>)(.*?)(</code></pre>)', re.S)


def plain(fragment):
    return html.unescape(re.sub(r"<[^>]+>", "", fragment))


def render_line(pieces):
    return "".join(html.escape(t, quote=False) if c is None
                   else f'<span class="{c}">{html.escape(t, quote=False)}</span>'
                   for c, t in pieces)


def rehighlight_block(body):
    rows = body.split("\n")
    parts = [LINE.match(row) for row in rows]
    if not all(parts):
        return body
    texts = [plain(p.group(2)) for p in parts]
    return "\n".join(p.group(1) + render_line(s) + p.group(3)
                     for p, s in zip(parts, stata_spans(texts)))


def rehighlight(page):
    return BLOCK.sub(lambda m: m.group(1) + rehighlight_block(m.group(2)) + m.group(3), page)


def rehighlight_site(site):
    for path in site.rglob("*.html"):
        text = path.read_text(encoding="utf-8")
        new = rehighlight(text)
        if new != text:
            path.write_text(new, encoding="utf-8")
