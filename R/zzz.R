#' cprd.search: Search the CPRD Aurum Medical Dictionary
#'
#' A tool for searching the CPRD Aurum Medical Dictionary by keywords.
#' Supports multi-keyword AND/OR searches, fuzzy matching, filtering,
#' and exporting results. Useful for building code lists for
#' epidemiological studies using CPRD data.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{load_cprd_dictionary}}}{Load the CPRD Aurum Medical Dictionary from a text file.}
#'   \item{\code{\link{cprd_search}}}{Search using AND logic (all keywords must match).}
#'   \item{\code{\link{cprd_search_or}}}{Search using OR logic (any keyword can match).}
#'   \item{\code{\link{cprd_search_fuzzy}}}{Fuzzy search for approximate matches.}
#'   \item{\code{\link{cprd_search_exclude}}}{Search with inclusion and exclusion keywords.}
#'   \item{\code{\link{cprd_export}}}{Export search results to CSV.}
#'   \item{\code{\link{cprd_browse}}}{Interactive browser for the dictionary.}
#' }
#'
#' @import data.table
#' @importFrom stringdist stringdist
#' @importFrom utils write.csv
"_PACKAGE"

# Suppress R CMD check notes for data.table NSE columns
utils::globalVariables(c(
    ".", "MedCodeId", "Term", "Observations", "OriginalReadCode",
    "CleansedReadCode", "SnomedCTConceptId", "SnomedCTDescriptionId",
    "Release", "EmisCodeCategoryId", "term_lower", ":=", "dist",
    "..export_cols", ".cprd_env"
))

# Package-level environment for storing the loaded dictionary
.cprd_env <- new.env(parent = emptyenv())
