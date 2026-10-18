synthetic_dictionary <- function() {
    utils::read.delim(system.file("extdata", "synthetic-dictionary.tsv",
                                 package = "cprd.search"),
                     colClasses = "character", check.names = FALSE)
}

local_dictionary <- function(data = synthetic_dictionary(), load = TRUE,
                             .local_envir = parent.frame()) {
    saved <- lapply(as.list(.cprd_env), data.table::copy)
    withr::defer({
        rm(list = ls(.cprd_env), envir = .cprd_env)
        list2env(saved, envir = .cprd_env)
    }, envir = .local_envir)
    rm(list = ls(.cprd_env), envir = .cprd_env)
    path <- tempfile(fileext = ".tsv")
    withr::defer(unlink(path), envir = .local_envir)
    utils::write.table(data, path, sep = "\t", quote = FALSE,
                       row.names = FALSE, na = "")
    if (load) suppressMessages(load_cprd_dictionary(path))
    path
}

ids <- function(x) x$MedCodeId
