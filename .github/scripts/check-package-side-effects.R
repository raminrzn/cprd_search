# Run the bundled examples, vignette code and tests from the exact archive.
# This maintainer-only audit is excluded from the CRAN package. Tracing is
# confined to this disposable R process, and detects writes before they happen.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
archive <- normalizePath(args[[1L]], mustWork = TRUE)
root <- tempfile("cprd-policy-audit-")
dir.create(root)
lib <- file.path(root, "library")
dir.create(lib)
status <- system2(file.path(R.home("bin"), "R"),
                  c("CMD", "INSTALL", "--install-tests", paste0("--library=", shQuote(lib)),
                    shQuote(archive)))
stopifnot(status == 0L)
.libPaths(c(lib, .libPaths()))
library(cprd.search)
loadNamespace("testthat")
loadNamespace("knitr")
utils::untar(archive, exdir = root)
src <- file.path(root, "cprd.search")

examples <- list.files(file.path(src, "man"), "[.]Rd$", full.names = TRUE)
scripts <- vapply(examples, function(rd) {
    out <- tempfile(tmpdir = root, fileext = ".R")
    tools::Rd2ex(rd, out = out)
    out
}, character(1))
scripts <- scripts[file.exists(scripts)] # Package overview has no example block.
example_count <- length(scripts)
scripts <- c(scripts, list.files(file.path(src, "inst", "examples"),
                               "[.]R$", full.names = TRUE))
vignettes <- list.files(file.path(src, "vignettes"), "[.]Rmd$", full.names = TRUE)
for (vignette in vignettes) {
    out <- tempfile(tmpdir = root, fileext = ".R")
    knitr::purl(vignette, output = out, documentation = 0, quiet = TRUE)
    scripts <- c(scripts, out)
}

writes <- character()
read_only <- paste0(normalizePath(c(src, find.package("cprd.search")), winslash = "/"), "/")
guard_path <- function(path) {
    if (is.null(path) || inherits(path, "connection")) return(invisible(NULL))
    stopifnot(is.character(path))
    path <- path[nzchar(path)] # "" denotes console output, not a file.
    if (!length(path)) return(invisible(NULL))
    # Resolve the existing parent even when the output file does not exist yet.
    # On macOS /var is a symlink, and tempfile() can contain a doubled slash.
    resolved <- vapply(path.expand(path), function(p) {
        file.path(normalizePath(dirname(p), winslash = "/", mustWork = TRUE), basename(p))
    }, character(1))
    temporary <- paste0(normalizePath(tempdir(), winslash = "/"), "/")
    if (any(!startsWith(paste0(resolved, "/"), temporary))) {
        stop("Write outside tempdir(): ", paste(path, collapse = ", "), call. = FALSE)
    }
    if (any(vapply(read_only, function(p) any(startsWith(paste0(resolved, "/"), p)), logical(1)))) {
        stop("Write into package source or installation: ", paste(path, collapse = ", "), call. = FALSE)
    }
    writes <<- c(writes, resolved)
    invisible(NULL)
}
guard_connection <- function(description, open) {
    if (grepl("[wa+]", open)) guard_path(description)
}
# Negative controls verify the guard itself before executing bundled code.
for (path in c(file.path(path.expand("~"), "cprd-audit-must-not-write.csv"),
               file.path(find.package("cprd.search"), "cprd-audit-must-not-write.csv"))) {
    stopifnot(inherits(tryCatch(guard_path(path), error = identity), "error"))
}
for (connection in c("file", "gzfile", "bzfile", "xzfile")) {
    trace(connection, where = baseenv(),
          tracer = quote(guard_connection(description, open)), print = FALSE)
}
trace("write.table", where = asNamespace("utils"), tracer = quote(guard_path(file)), print = FALSE)
trace("writeLines", where = baseenv(), tracer = quote(guard_path(con)), print = FALSE)
trace("saveRDS", where = baseenv(), tracer = quote(guard_path(file)), print = FALSE)
trace("cat", where = baseenv(), tracer = quote(guard_path(file)), print = FALSE)
trace("sink", where = baseenv(), tracer = quote(guard_path(file)), print = FALSE)
trace("dir.create", where = baseenv(), tracer = quote(guard_path(path)), print = FALSE)
trace("unlink", where = baseenv(), tracer = quote(guard_path(x)), print = FALSE)
trace("file.create", where = baseenv(), tracer = quote(guard_path(c(...))), print = FALSE)
trace("file.copy", where = baseenv(), tracer = quote(guard_path(to)), print = FALSE)
trace("file.rename", where = baseenv(),
      tracer = quote({ guard_path(from); guard_path(to) }), print = FALSE)
for (external in c("browseURL", "download.file")) {
    trace(external, where = asNamespace("utils"),
          tracer = quote(stop("Unexpected browser or network access", call. = FALSE)), print = FALSE)
}

for (script in scripts) {
    cat("Auditing ", basename(script), "\n", sep = "")
    source(script, local = new.env(parent = globalenv()))
}
testthat::test_package("cprd.search", reporter = "summary", stop_on_failure = TRUE)
cat("Policy audit passed: ", example_count, " help examples, ",
    length(vignettes), " vignette(s), installed example script and full test suite.\n",
    "All ", length(writes), " observed file operations stayed inside tempdir(); ",
    "no browser or download was invoked.\n", sep = "")
unlink(root, recursive = TRUE)
