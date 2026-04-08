#' Search the CPRD Dictionary (AND logic)
#'
#' Search for medical terms where ALL keywords appear in the term description.
#' This is useful for specific searches like "family history" + "lung cancer".
#'
#' @param ... Character strings. One or more keywords to search for.
#'   All keywords must be present in the term (AND logic).
#' @param min_obs Integer. Minimum number of observations to include.
#'   Default is 0 (include all). Set higher to filter rare codes.
#' @param column Character. Which column to search in. Default is "Term".
#'   Can also be "OriginalReadCode", "CleansedReadCode", "MedCodeId", or
#'   "SnomedCTConceptId".
#'
#' @return A \code{data.table} with matching rows, sorted by number of
#'   observations (most frequent first).
#'
#' @examples
#' \dontrun{
#' # Search for family history of lung cancer
#' cprd_search("family history", "lung cancer")
#'
#' # Search for diabetes terms with at least 100 observations
#' cprd_search("diabetes", min_obs = 100)
#'
#' # Search by Read code
#' cprd_search("H33", column = "CleansedReadCode")
#' }
#'
#' @export
cprd_search <- function(..., min_obs = 0, column = "Term") {
    dict <- get_dictionary()
    keywords <- tolower(unlist(list(...)))

    if (length(keywords) == 0) {
        stop("Please provide at least one keyword.", call. = FALSE)
    }

    # Determine which column to search
    if (column == "Term") {
        search_col <- dict$term_lower
    } else {
        if (!column %in% names(dict)) {
            stop("Column '", column, "' not found in dictionary.", call. = FALSE)
        }
        search_col <- tolower(as.character(dict[[column]]))
    }

    # AND logic: all keywords must be present
    matches <- rep(TRUE, nrow(dict))
    for (kw in keywords) {
        matches <- matches & grepl(kw, search_col, fixed = FALSE)
    }

    result <- dict[matches]

    # Filter by minimum observations
    if (min_obs > 0) {
        result <- result[Observations >= min_obs]
    }

    # Sort by observations (most common first)
    result <- result[order(-Observations)]

    # Remove the helper column from output
    out <- result[, .(MedCodeId, Term, Observations, OriginalReadCode,
                       CleansedReadCode, SnomedCTConceptId,
                       SnomedCTDescriptionId, Release, EmisCodeCategoryId)]

    message("Found ", format(nrow(out), big.mark = ","), " matching terms.")
    out
}


#' Search the CPRD Dictionary (OR logic)
#'
#' Search for medical terms where ANY keyword appears in the term description.
#' Useful for broad searches across related concepts.
#'
#' @param ... Character strings. One or more keywords to search for.
#'   At least one keyword must be present (OR logic).
#' @param min_obs Integer. Minimum number of observations. Default is 0.
#' @param column Character. Which column to search in. Default is "Term".
#'
#' @return A \code{data.table} with matching rows, sorted by observations.
#'
#' @examples
#' \dontrun{
#' # Search for any mention of lung cancer or bronchial cancer
#' cprd_search_or("lung cancer", "bronchial cancer", "pulmonary cancer")
#' }
#'
#' @export
cprd_search_or <- function(..., min_obs = 0, column = "Term") {
    dict <- get_dictionary()
    keywords <- tolower(unlist(list(...)))

    if (length(keywords) == 0) {
        stop("Please provide at least one keyword.", call. = FALSE)
    }

    if (column == "Term") {
        search_col <- dict$term_lower
    } else {
        if (!column %in% names(dict)) {
            stop("Column '", column, "' not found in dictionary.", call. = FALSE)
        }
        search_col <- tolower(as.character(dict[[column]]))
    }

    # OR logic: any keyword can match
    matches <- rep(FALSE, nrow(dict))
    for (kw in keywords) {
        matches <- matches | grepl(kw, search_col, fixed = FALSE)
    }

    result <- dict[matches]

    if (min_obs > 0) {
        result <- result[Observations >= min_obs]
    }

    result <- result[order(-Observations)]

    out <- result[, .(MedCodeId, Term, Observations, OriginalReadCode,
                       CleansedReadCode, SnomedCTConceptId,
                       SnomedCTDescriptionId, Release, EmisCodeCategoryId)]

    message("Found ", format(nrow(out), big.mark = ","), " matching terms.")
    out
}


#' Search with Exclusions
#'
#' Search for terms matching inclusion keywords but NOT matching any
#' exclusion keywords. Useful for refining broad searches.
#'
#' @param include Character vector. Keywords that MUST be present (AND logic).
#' @param exclude Character vector. Keywords that must NOT be present.
#' @param min_obs Integer. Minimum number of observations. Default is 0.
#' @param or_logic Logical. If TRUE, use OR logic for inclusion keywords.
#'   Default is FALSE (AND logic).
#'
#' @return A \code{data.table} with matching rows.
#'
#' @examples
#' \dontrun{
#' # Family history of cancer, but not breast cancer
#' cprd_search_exclude(
#'   include = c("family history", "cancer"),
#'   exclude = c("breast")
#' )
#'
#' # Diabetes terms, excluding gestational
#' cprd_search_exclude(
#'   include = c("diabetes"),
#'   exclude = c("gestational", "pregnancy")
#' )
#' }
#'
#' @export
cprd_search_exclude <- function(include, exclude = NULL, min_obs = 0,
                                 or_logic = FALSE) {
    dict <- get_dictionary()
    include <- tolower(include)
    search_col <- dict$term_lower

    # Apply inclusion
    if (or_logic) {
        matches <- rep(FALSE, nrow(dict))
        for (kw in include) {
            matches <- matches | grepl(kw, search_col, fixed = FALSE)
        }
    } else {
        matches <- rep(TRUE, nrow(dict))
        for (kw in include) {
            matches <- matches & grepl(kw, search_col, fixed = FALSE)
        }
    }

    # Apply exclusions
    if (!is.null(exclude)) {
        exclude <- tolower(exclude)
        for (kw in exclude) {
            matches <- matches & !grepl(kw, search_col, fixed = FALSE)
        }
    }

    result <- dict[matches]

    if (min_obs > 0) {
        result <- result[Observations >= min_obs]
    }

    result <- result[order(-Observations)]

    out <- result[, .(MedCodeId, Term, Observations, OriginalReadCode,
                       CleansedReadCode, SnomedCTConceptId,
                       SnomedCTDescriptionId, Release, EmisCodeCategoryId)]

    message("Found ", format(nrow(out), big.mark = ","), " matching terms.")
    out
}


#' Fuzzy Search the CPRD Dictionary
#'
#' Search for medical terms using approximate (fuzzy) string matching.
#' Useful when you're unsure of exact spelling.
#'
#' @param term Character string. The term to search for.
#' @param max_dist Numeric. Maximum string distance for a match.
#'   Default is 2. Lower = stricter matching.
#' @param method Character. Distance method: "osa" (default), "lv",
#'   "dl", "hamming", "lcs", "qgram", "cosine", "jaccard", "jw".
#' @param min_obs Integer. Minimum observations. Default is 0.
#' @param max_results Integer. Maximum number of results. Default is 50.
#'
#' @return A \code{data.table} with matching rows, sorted by distance
#'   (best matches first).
#'
#' @examples
#' \dontrun{
#' # Fuzzy search for "diabeties" (misspelled)
#' cprd_search_fuzzy("diabeties")
#'
#' # Stricter matching
#' cprd_search_fuzzy("hypertension", max_dist = 1)
#' }
#'
#' @export
cprd_search_fuzzy <- function(term, max_dist = 2, method = "jw",
                               min_obs = 0, max_results = 50) {
    dict <- get_dictionary()
    search_term <- tolower(term)

    # Extract unique words from each term for comparison
    terms_lower <- dict$term_lower

    # Compute string distances
    # For efficiency, first do a rough filter using substring matching
    # on individual words from the search term
    words <- unlist(strsplit(search_term, "\\s+"))

    # Pre-filter: keep rows containing at least a partial match
    pre_filter <- rep(FALSE, nrow(dict))
    for (w in words) {
        # Allow first 3 characters to match
        if (nchar(w) >= 3) {
            pre_filter <- pre_filter | grepl(substr(w, 1, 3), terms_lower, fixed = TRUE)
        } else {
            pre_filter <- pre_filter | grepl(w, terms_lower, fixed = TRUE)
        }
    }

    candidates <- dict[pre_filter]

    if (nrow(candidates) == 0) {
        message("No fuzzy matches found.")
        return(data.table::data.table())
    }

    # Compute distance on the candidate set
    distances <- stringdist::stringdist(search_term, candidates$term_lower,
                                         method = method)
    candidates[, dist := distances]

    # Filter by max distance
    result <- candidates[dist <= max_dist]

    if (min_obs > 0) {
        result <- result[Observations >= min_obs]
    }

    # Sort by distance, then by observations
    result <- result[order(dist, -Observations)]

    # Limit results
    if (nrow(result) > max_results) {
        result <- result[1:max_results]
    }

    out <- result[, .(MedCodeId, Term, Observations, OriginalReadCode,
                       CleansedReadCode, SnomedCTConceptId, dist)]

    message("Found ", format(nrow(out), big.mark = ","), " fuzzy matches.")
    out
}
