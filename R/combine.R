#' Format search results
#'
#' Internal helper that applies column selection and converts to tibble.
#'
#' @param result A data.table of raw search results.
#' @param select Character vector of column names to return, or NULL for all.
#' @return A tibble with the selected columns.
#' @keywords internal
format_results <- function(result, select = NULL) {
    # All available output columns (exclude internal helper columns)
    all_cols <- c("MedCodeId", "Term", "Observations", "OriginalReadCode",
                  "CleansedReadCode", "SnomedCTConceptId",
                  "SnomedCTDescriptionId", "Release", "EmisCodeCategoryId")

    if (is.null(select)) {
        select_cols <- all_cols
    } else {
        # Validate column names
        bad <- setdiff(select, all_cols)
        if (length(bad) > 0) {
            stop("Unknown column(s): ", paste(bad, collapse = ", "),
                 "\nAvailable: ", paste(all_cols, collapse = ", "),
                 call. = FALSE)
        }
        select_cols <- select
    }

    out <- result[, ..select_cols]

    message("Found ", format(nrow(out), big.mark = ","), " matching terms.")
    tibble::as_tibble(out)
}


#' Combine Multiple Search Results
#'
#' Combine results from multiple searches into one de-duplicated table.
#' Useful when building a comprehensive code list from different search
#' strategies.
#'
#' @param ... Two or more search result tibbles/data.frames to combine.
#' @param select Character vector of columns to keep, or NULL for all.
#'   Default is NULL.
#'
#' @return A tibble with all unique rows, sorted by Observations
#'   (most frequent first).
#'
#' @examples
#' \dontrun{
#' # Build a comprehensive lung cancer code list
#' r1 <- cprd_search("lung cancer")
#' r2 <- cprd_search("bronchial carcinoma")
#' r3 <- cprd_search("pulmonary neoplasm")
#'
#' all_codes <- cprd_combine(r1, r2, r3)
#' print(all_codes)
#'
#' # Combine and keep only MedCodeId and Term
#' all_codes <- cprd_combine(r1, r2, r3, select = c("MedCodeId", "Term"))
#' }
#'
#' @export
cprd_combine <- function(..., select = NULL) {
    results_list <- list(...)

    if (length(results_list) < 1) {
        stop("Please provide at least one result set to combine.", call. = FALSE)
    }

    # Convert all to data.tables and bind
    combined <- data.table::rbindlist(
        lapply(results_list, data.table::as.data.table),
        fill = TRUE
    )

    # De-duplicate by MedCodeId
    combined <- unique(combined, by = "MedCodeId")

    # Sort by observations
    combined <- combined[order(-Observations)]

    # Apply column selection
    if (!is.null(select)) {
        bad <- setdiff(select, names(combined))
        if (length(bad) > 0) {
            stop("Unknown column(s): ", paste(bad, collapse = ", "), call. = FALSE)
        }
        select_cols <- select
        combined <- combined[, ..select_cols]
    }

    message("Combined: ", format(nrow(combined), big.mark = ","),
            " unique terms.")
    tibble::as_tibble(combined)
}
