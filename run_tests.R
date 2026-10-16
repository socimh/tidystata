# Run from the package root through the protected Windows R launcher.
# Build in a temporary copy so old local DLLs never influence the result.
args <- commandArgs(trailingOnly = TRUE)
command <- c(".opencode/workflows/verify_package.py")
if (length(args)) command <- c(command, "--filter", shQuote(args[[1L]]))
status <- system2("python", command)
quit(status = status)
