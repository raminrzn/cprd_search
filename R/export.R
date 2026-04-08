#' Export Search Results to CSV
#'
#' Save search results to a CSV file for use in other tools or for
#' building a final code list.
#'
#' @param results A \code{data.table} of search results (from any search function).
#' @param filename Character string. Output file path. Default is
#'   "cprd_search_results.csv".
#' @param open Logical. If TRUE, attempt to open the file after saving.
#'   Default is FALSE.
#'
#' @return The file path (invisibly).
#'
#' @examples
#' \dontrun{
#' results <- cprd_search("family history", "lung cancer")
#' cprd_export(results, "fh_lung_cancer_codes.csv")
#' }
#'
#' @export
cprd_export <- function(results, filename = "cprd_search_results.csv",
                         open = FALSE) {
    if (!is.data.frame(results)) {
        stop("'results' must be a data.frame or data.table.", call. = FALSE)
    }

    # Remove internal columns if present
    export_cols <- setdiff(names(results), c("term_lower", "dist"))
    out <- results[, ..export_cols]

    write.csv(out, file = filename, row.names = FALSE)
    message("Exported ", format(nrow(out), big.mark = ","),
            " rows to: ", filename)

    if (open && interactive()) {
        utils::browseURL(filename)
    }

    invisible(filename)
}


#' Interactive Dictionary Browser
#'
#' An interactive console-based browser that lets you search the dictionary
#' repeatedly without re-typing function calls. Type 'q' to quit.
#'
#' @param min_obs Integer. Minimum observations filter. Default is 0.
#'
#' @return NULL (called for side effects).
#'
#' @examples
#' \dontrun{
#' cprd_browse()
#' # Then type keywords at the prompt, e.g.:
#' # > family history lung cancer
#' # > q   (to quit)
#' }
#'
#' @export
cprd_browse <- function(min_obs = 0) {
    if (!interactive()) {
        stop("cprd_browse() can only be used interactively.", call. = FALSE)
    }

    dict <- get_dictionary()

    cat("\n===== CPRD Aurum Medical Dictionary Browser =====\n")
    cat("Type keywords to search (AND logic).\n")
    cat("Prefix with 'OR:' for OR logic, e.g., 'OR: asthma, copd'\n")
    cat("Prefix with '-' to exclude, e.g., 'diabetes -gestational'\n")
    cat("Type 'q' to quit.\n\n")

    repeat {
        input <- readline(prompt = "Search> ")

        if (tolower(trimws(input)) == "q") {
            cat("Goodbye!\n")
            break
        }

        if (nchar(trimws(input)) == 0) next

        tryCatch({
            # Check for OR logic
            if (grepl("^OR:", input, ignore.case = TRUE)) {
                terms <- trimws(unlist(strsplit(sub("^OR:\\s*", "", input), ",")))
                results <- cprd_search_or(terms, min_obs = min_obs)
            } else {
                # Parse include/exclude
                parts <- trimws(unlist(strsplit(input, "\\s+")))
                exclude_idx <- grepl("^-", parts)
                exclude_terms <- sub("^-", "", parts[exclude_idx])
                include_terms <- parts[!exclude_idx]

                if (length(exclude_terms) > 0) {
                    results <- cprd_search_exclude(
                        include = include_terms,
                        exclude = exclude_terms,
                        min_obs = min_obs
                    )
                } else {
                    results <- cprd_search(include_terms, min_obs = min_obs)
                }
            }

            if (nrow(results) > 0) {
                # Show top results
                n_show <- min(20, nrow(results))
                print(results[1:n_show, .(MedCodeId, Term, Observations)])
                if (nrow(results) > n_show) {
                    cat("... and", nrow(results) - n_show, "more results.\n")
                }
            }
            cat("\n")
        }, error = function(e) {
            cat("Error:", e$message, "\n\n")
        })
    }

    invisible(NULL)
}
