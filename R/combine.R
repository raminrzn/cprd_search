#' Combine Multiple Search Results
#'
#' Combine search result tables, keeping the first occurrence of each
#' `MedCodeId`. Columns absent from an input are filled with missing values.
#' @param ... One or more search result tibbles, data.frames, or data.tables.
#'   Each must contain a non-missing, non-empty `MedCodeId` column.
#' @param select Character vector of columns to keep, or `NULL` for all.
#' @return A tibble deduplicated by `MedCodeId`, sorted by decreasing
#'   `Observations` when available (missing counts last). Otherwise input order
#'   is preserved. Conflicting duplicate rows use the first row, without merging
#'   its values with later rows.
#' @examples
#' load_cprd_dictionary(system.file("extdata", "synthetic-dictionary.tsv",
#'                                  package = "cprd.search"))
#' a <- cprd_search("diabetes", select = c("MedCodeId", "Term"))
#' b <- cprd_search_or("diabetes", "asthma", select = c("MedCodeId", "Term"))
#' cprd_combine(a, b)
#' @export
cprd_combine <- function(..., select = NULL) {
    results <- list(...)
    if (!length(results)) stop("Please provide at least one result set to combine.", call. = FALSE)
    results <- lapply(results, function(x) {
        if (!is.data.frame(x) || !"MedCodeId" %in% names(x)) {
            stop("Each result must be a data.frame with a 'MedCodeId' column.", call. = FALSE)
        }
        x <- as.data.frame(x)
        x$MedCodeId <- as.character(x$MedCodeId)
        check_text(x$MedCodeId, "MedCodeId", empty = TRUE)
        if ("Observations" %in% names(x) && !is.numeric(x$Observations)) {
            stop("'Observations' must be numeric when present.", call. = FALSE)
        }
        x
    })
    combined <- tibble::as_tibble(data.table::rbindlist(results, use.names = TRUE, fill = TRUE))
    combined <- combined[!duplicated(combined$MedCodeId), , drop = FALSE]
    if ("Observations" %in% names(combined)) {
        combined <- combined[order(-combined$Observations, na.last = TRUE), , drop = FALSE]
    }
    combined <- select_columns(combined, select)
    message("Combined: ", nrow(combined), " unique terms.")
    combined
}
