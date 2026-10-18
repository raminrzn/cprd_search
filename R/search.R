#' Search the CPRD Dictionary with AND Logic
#'
#' Find rows containing every supplied keyword. Matching is case-insensitive
#' and uses literal substrings unless `regex = TRUE`.
#' @param ... One or more character strings or character vectors of keywords.
#'   Empty strings and missing values are not accepted.
#' @param min_obs Non-negative whole number giving the minimum observation
#'   count. Zero includes rows with missing counts; positive values exclude them.
#' @param column Name of the dictionary column to search. Default is `"Term"`.
#' @param select Character vector of column names to return, or `NULL` for all
#'   dictionary columns except the internal `term_lower` column.
#' @param regex Logical. Interpret keywords as regular expressions if `TRUE`.
#'   The default is `FALSE`, so punctuation in medical codes is literal.
#' @return A tibble, sorted by decreasing `Observations`, with missing counts
#'   last. No matches returns a zero-row tibble with the same columns and types.
#' @examples
#' load_cprd_dictionary(system.file("extdata", "synthetic-dictionary.tsv",
#'                                  package = "cprd.search"))
#' cprd_search("family history", "lung cancer")
#' cprd_search("diabetes", min_obs = 50, select = c("MedCodeId", "Term"))
#' cprd_search("H33..", column = "CleansedReadCode")
#' cprd_search("^asthma$", regex = TRUE)
#' @export
cprd_search <- function(..., min_obs = 0, column = "Term", select = NULL,
                        regex = FALSE) {
    search_dictionary(collect_keywords(...), min_obs, column, select, regex)
}

#' Search the CPRD Dictionary with OR Logic
#'
#' Find rows containing any supplied keyword, using case-insensitive matching.
#' @inheritParams cprd_search
#' @inherit cprd_search return
#' @examples
#' load_cprd_dictionary(system.file("extdata", "synthetic-dictionary.tsv",
#'                                  package = "cprd.search"))
#' cprd_search_or("asthma", "lung cancer", select = c("MedCodeId", "Term"))
#' @export
cprd_search_or <- function(..., min_obs = 0, column = "Term", select = NULL,
                           regex = FALSE) {
    search_dictionary(collect_keywords(...), min_obs, column, select, regex,
                      any_match = TRUE)
}

#' Search with Exclusions
#'
#' Find rows matching inclusion keywords but none of the exclusion keywords.
#' Matching is case-insensitive and literal unless `regex = TRUE`.
#' @param include Non-empty character vector of inclusion keywords.
#' @param exclude Character vector of exclusion keywords, or `NULL`.
#' @param or_logic Logical. Match any inclusion keyword if `TRUE`, or every
#'   inclusion keyword if `FALSE` (the default).
#' @inheritParams cprd_search
#' @inherit cprd_search return
#' @examples
#' load_cprd_dictionary(system.file("extdata", "synthetic-dictionary.tsv",
#'                                  package = "cprd.search"))
#' cprd_search_exclude("diabetes", exclude = "gestational")
#' @export
cprd_search_exclude <- function(include, exclude = NULL, min_obs = 0,
                                 or_logic = FALSE, select = NULL,
                                 column = "Term", regex = FALSE) {
    check_text(include, "include")
    if (is.null(exclude)) exclude <- character()
    check_text(exclude, "exclude", empty = TRUE)
    check_flag(or_logic, "or_logic")
    search_dictionary(include, min_obs, column, select, regex,
                      any_match = or_logic, exclude = exclude)
}

#' Fuzzy Search Complete Dictionary Terms
#'
#' Compare a query with complete, case-insensitive term descriptions using
#' string distances. Every eligible term is compared; no prefix filter is used.
#' @param term One non-empty character string to compare with `Term`.
#' @param max_dist Maximum distance to accept. `NULL` uses 2 for edit/count
#'   distances and 0.1 for `"jw"`, `"cosine"`, or `"jaccard"`. For these
#'   normalized methods the threshold must be between 0 and 1.
#' @param method Distance method: `"osa"` (default), `"lv"`, `"dl"`,
#'   `"hamming"`, `"lcs"`, `"qgram"`, `"cosine"`, `"jaccard"`, or `"jw"`.
#'   See [stringdist::stringdist-metrics] for definitions. `"jw"` uses Jaro
#'   distance with the default prefix weight of zero.
#' @param max_results Non-negative whole number limiting the result count.
#'   Zero returns a correctly typed, empty result.
#' @inheritParams cprd_search
#' @return A tibble containing dictionary columns and numeric `dist`, ordered
#'   by increasing distance, then decreasing observations. `select` can include
#'   `dist`. Missing or empty descriptions do not match.
#' @details Distances compare the whole query with the whole description, not
#'   individual words or substrings. Thus `"diabeties"` can match `"diabetes"`
#'   at an edit distance of 1, but a longer description such as
#'   `"gestational diabetes"` requires a larger edit threshold. Use
#'   [cprd_search()] for literal substring searches. Search candidates still
#'   require review when building a study code list.
#' @examples
#' load_cprd_dictionary(system.file("extdata", "synthetic-dictionary.tsv",
#'                                  package = "cprd.search"))
#' cprd_search_fuzzy("diabeties", select = c("MedCodeId", "Term", "dist"))
#' cprd_search_fuzzy("xiabetes", max_dist = 1)
#' cprd_search_fuzzy("diabeties", method = "jw", max_dist = 0.1)
#' @export
cprd_search_fuzzy <- function(term, max_dist = NULL, method = "osa",
                               min_obs = 0, max_results = 50, select = NULL) {
    check_text(term, "term", scalar = TRUE)
    check_text(method, "method", scalar = TRUE)
    methods <- c("osa", "lv", "dl", "hamming", "lcs", "qgram", "cosine", "jaccard", "jw")
    if (!method %in% methods) stop("Unknown distance method: ", method, call. = FALSE)
    normalized <- method %in% c("jw", "cosine", "jaccard")
    if (is.null(max_dist)) max_dist <- if (normalized) 0.1 else 2
    check_number(max_dist, "max_dist")
    if (normalized && max_dist > 1) {
        stop("'max_dist' must be between 0 and 1 for method '", method, "'.", call. = FALSE)
    }
    check_number(min_obs, "min_obs", whole = TRUE)
    check_number(max_results, "max_results", whole = TRUE)
    dict <- get_dictionary()
    text <- dict[["term_lower"]]
    rows <- which(!is.na(text) & nzchar(text) &
                  observation_filter(dict[["Observations"]], min_obs))
    distances <- stringdist::stringdist(tolower(term), text[rows],
                                        method = method, nthread = 1L)
    keep <- which(!is.na(distances) & distances <= max_dist)
    rows <- rows[keep]
    distances <- distances[keep]
    ordering <- order(distances, -dict[["Observations"]][rows], na.last = TRUE)
    ordering <- utils::head(ordering, max_results)
    result <- format_results(dict[rows[ordering]])
    result$dist <- distances[ordering]
    result <- select_columns(result, select)
    message("Found ", nrow(result), " fuzzy matches.")
    result
}
