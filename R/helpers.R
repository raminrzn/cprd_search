# Shared argument checks and output handling.
check_flag <- function(x, name) {
    if (!is.logical(x) || length(x) != 1L || is.na(x)) {
        stop("'", name, "' must be TRUE or FALSE.", call. = FALSE)
    }
}

check_number <- function(x, name, whole = FALSE) {
    if (!is.numeric(x) || length(x) != 1L || is.na(x) ||
        !is.finite(x) || x < 0 || (whole && x != floor(x))) {
        stop("'", name, "' must be a finite non-negative ",
             if (whole) "whole number." else "number.", call. = FALSE)
    }
}

check_text <- function(x, name, scalar = FALSE, empty = FALSE) {
    if (!is.character(x) || (scalar && length(x) != 1L) ||
        (!empty && length(x) == 0L) || anyNA(x) ||
        any(!nzchar(trimws(x)))) {
        stop("'", name, "' must contain ",
             if (scalar) "one non-empty string." else "non-empty strings without NA.",
             call. = FALSE)
    }
    x
}

collect_keywords <- function(...) {
    args <- list(...)
    if (!length(args)) stop("Please provide at least one keyword.", call. = FALSE)
    for (arg in args) check_text(arg, "keywords")
    unlist(args, use.names = FALSE)
}

select_columns <- function(x, select) {
    if (is.null(select)) return(x)
    check_text(select, "select")
    if (anyDuplicated(select)) stop("'select' must not contain duplicates.", call. = FALSE)
    bad <- setdiff(select, names(x))
    if (length(bad)) {
        stop("Unknown column(s): ", paste(bad, collapse = ", "),
             ". Available: ", paste(names(x), collapse = ", "), call. = FALSE)
    }
    x[, select, drop = FALSE]
}

format_results <- function(result, select = NULL) {
    out <- tibble::as_tibble(result)
    out <- out[, setdiff(names(out), "term_lower"), drop = FALSE]
    select_columns(out, select)
}

keyword_matches <- function(text, keywords, regex, any_match = FALSE) {
    matches <- rep(!any_match, length(text))
    if (!regex) {
        text <- tolower(text)
        keywords <- tolower(keywords)
    }
    for (keyword in keywords) {
        hit <- tryCatch(
            suppressWarnings(if (regex) grepl(keyword, text, ignore.case = TRUE)
                             else grepl(keyword, text, fixed = TRUE)),
            error = function(e) stop("Invalid regular expression: ", keyword,
                                     call. = FALSE)
        )
        hit[is.na(text) | !nzchar(text)] <- FALSE
        matches <- if (any_match) matches | hit else matches & hit
    }
    matches
}

observation_filter <- function(observations, min_obs) {
    if (min_obs == 0) return(rep(TRUE, length(observations)))
    !is.na(observations) & observations >= min_obs
}

search_dictionary <- function(keywords, min_obs, column, select, regex,
                              any_match = FALSE, exclude = character()) {
    check_number(min_obs, "min_obs", whole = TRUE)
    check_flag(regex, "regex")
    check_text(column, "column", scalar = TRUE)
    dict <- get_dictionary()
    if (!column %in% setdiff(names(dict), "term_lower")) {
        stop("Column '", column, "' not found in dictionary.", call. = FALSE)
    }
    text <- if (column == "Term" && !regex) dict[["term_lower"]] else as.character(dict[[column]])
    matches <- keyword_matches(text, keywords, regex, any_match)
    if (length(exclude)) {
        matches <- matches & !keyword_matches(text, exclude, regex, any_match = TRUE)
    }
    matches <- matches & observation_filter(dict[["Observations"]], min_obs)
    rows <- which(matches)
    rows <- rows[order(-dict[["Observations"]][rows], na.last = TRUE)]
    result <- format_results(dict[rows], select)
    message("Found ", nrow(result), " matching terms.")
    result
}
