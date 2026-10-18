#' Export Search Results to CSV
#'
#' Save a tibble, data.frame, or data.table of search results to a UTF-8 CSV.
#' Internal `term_lower` and fuzzy `dist` columns are omitted.
#' @param results A tibble, data.frame, or data.table of search results.
#' @param filename Output path. An existing file is overwritten.
#' @param open Logical. Open the saved file only when `TRUE` and interactive.
#' @return The supplied file path, invisibly.
#' @details Character identifiers are written without numeric conversion.
#'   When importing the CSV, specify character types for identifier columns
#'   (for example, `colClasses = "character"` in [utils::read.csv()]) to avoid
#'   another application removing leading zeroes or rounding long identifiers.
#' @examples
#' load_cprd_dictionary(system.file("extdata", "synthetic-dictionary.tsv",
#'                                  package = "cprd.search"))
#' results <- cprd_search("diabetes")
#' file <- tempfile(fileext = ".csv")
#' cprd_export(results, file)
#' utils::read.csv(file, colClasses = "character")
#' unlink(file)
#' @export
cprd_export <- function(results, filename = "cprd_search_results.csv", open = FALSE) {
    if (!is.data.frame(results)) {
        stop("'results' must be a tibble, data.frame, or data.table.", call. = FALSE)
    }
    check_text(filename, "filename", scalar = TRUE)
    check_flag(open, "open")
    out <- as.data.frame(results)
    out <- out[, setdiff(names(out), c("term_lower", "dist")), drop = FALSE]
    utils::write.csv(out, file = filename, row.names = FALSE, fileEncoding = "UTF-8")
    message("Exported ", nrow(out), " rows to: ", filename)
    if (open && interactive()) utils::browseURL(normalizePath(filename, mustWork = TRUE))
    invisible(filename)
}

#' Interactive Dictionary Browser
#'
#' Repeatedly search the loaded dictionary at a console prompt. Space-separated
#' keywords use AND logic. Use `OR: asthma, diabetes` for OR logic, or
#' `diabetes -gestational` for exclusions. Prefixes are case-insensitive.
#' Type `q` to quit. Keywords are literal, case-insensitive substrings.
#' @param min_obs Non-negative whole number giving the minimum observation count.
#' @return `NULL`, invisibly, for its printing and prompting side effects.
#' @examples
#' if (interactive()) {
#'     load_cprd_dictionary(system.file("extdata", "synthetic-dictionary.tsv",
#'                                      package = "cprd.search"))
#'     cprd_browse()
#' }
#' @export
cprd_browse <- function(min_obs = 0) {
    if (!interactive()) stop("cprd_browse() can only be used interactively.", call. = FALSE)
    check_number(min_obs, "min_obs", whole = TRUE)
    get_dictionary()
    browse_loop(min_obs)
}

browse_query <- function(input, min_obs) {
    input <- trimws(input)
    if (grepl("^OR:", input, ignore.case = TRUE)) {
        keywords <- trimws(strsplit(sub("^OR:\\s*", "", input, ignore.case = TRUE), ",")[[1L]])
        cprd_search_or(keywords, min_obs = min_obs)
    } else {
        parts <- strsplit(input, "\\s+")[[1L]]
        exclude <- grepl("^-", parts)
        cprd_search_exclude(parts[!exclude], sub("^-", "", parts[exclude]), min_obs)
    }
}

browse_loop <- function(min_obs, input = readline) {
    cat("CPRD Aurum Medical Dictionary Browser\n",
        "Use keywords, OR: asthma, diabetes, or diabetes -gestational.\n",
        "Type q to quit.\n", sep = "")
    repeat {
        query <- input("Search> ")
        if (!length(query) || is.na(query) || tolower(trimws(query)) == "q") break
        if (!nzchar(trimws(query))) next
        tryCatch({
            results <- browse_query(query, min_obs)
            n_show <- min(20L, nrow(results))
            print(results[seq_len(n_show), c("MedCodeId", "Term", "Observations"), drop = FALSE])
            if (nrow(results) > n_show) cat("... and", nrow(results) - n_show, "more results.\n")
        }, error = function(e) cat("Error:", conditionMessage(e), "\n"))
    }
    invisible(NULL)
}
