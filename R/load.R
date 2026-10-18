#' Load the CPRD Aurum Medical Dictionary
#'
#' Read a user-supplied tab-delimited dictionary and cache it for searching.
#' The package includes only a small, entirely synthetic example dictionary.
#'
#' @param filepath Path to a dictionary file. With `NULL`, reuse the cached
#'   dictionary or look for `CPRDAurumMedical.txt` in the working directory.
#' @param force Logical. Reload the file even when its path is already cached.
#' @return An independent copy of the loaded `data.table`, invisibly. Identifier
#'   columns are character, `Observations` is numeric, and `term_lower` is an
#'   internal lowercase copy of `Term`.
#' @details Required columns are `MedCodeId`, `Term`, and `Observations`.
#'   Standard additional columns are `OriginalReadCode`, `CleansedReadCode`,
#'   `SnomedCTConceptId`, `SnomedCTDescriptionId`, `Release`, and
#'   `EmisCodeCategoryId`. All columns except `Observations` are read as character
#'   to preserve identifiers. Observation counts must be non-negative whole
#'   numbers; blank or `NA` counts are treated as missing. Missing terms do not
#'   match searches. Empty or missing medical code identifiers are rejected.
#'
#'   Supplying a different path loads a new dictionary. Failed loads leave the
#'   previous cache intact. Use `force = TRUE` after changing a cached file.
#'   Real dictionaries must be obtained separately through the Clinical Practice
#'   Research Datalink; see <https://www.cprd.com/> for access information.
#' @examples
#' path <- system.file("extdata", "synthetic-dictionary.tsv", package = "cprd.search")
#' dict <- load_cprd_dictionary(path)
#' nrow(dict)
#' @export
load_cprd_dictionary <- function(filepath = NULL, force = FALSE) {
    check_flag(force, "force")
    cached <- exists("dictionary", envir = .cprd_env, inherits = FALSE)
    if (is.null(filepath)) {
        if (cached && !force) return(invisible(data.table::copy(.cprd_env$dictionary)))
        filepath <- if (cached) .cprd_env$filepath else "CPRDAurumMedical.txt"
    }
    check_text(filepath, "filepath", scalar = TRUE)
    filepath <- normalizePath(path.expand(filepath), mustWork = FALSE)
    if (!file.exists(filepath) || dir.exists(filepath)) {
        stop("File not found: ", filepath, call. = FALSE)
    }
    if (cached && !force && identical(filepath, .cprd_env$filepath)) {
        return(invisible(data.table::copy(.cprd_env$dictionary)))
    }
    # Reading all columns as character prevents loss of leading zeroes and
    # rounding of identifiers beyond double-precision integer accuracy.
    read_problems <- character()
    dict <- withCallingHandlers(data.table::fread(
        file = filepath, sep = "\t", header = TRUE, quote = "", fill = FALSE,
        colClasses = "character", na.strings = NULL, encoding = "UTF-8",
        nThread = 1L, showProgress = FALSE, check.names = FALSE
    ), warning = function(w) {
        # Let fread finish cleaning up its native resources before rejecting
        # the result; stopping inside its warning handler can interrupt cleanup.
        read_problems <<- c(read_problems, conditionMessage(w))
        invokeRestart("muffleWarning")
    })
    if (length(read_problems)) {
        stop("Cannot read dictionary completely: ", paste(read_problems, collapse = "; "),
             call. = FALSE)
    }
    if (anyDuplicated(names(dict)) || any(!nzchar(names(dict)))) {
        stop("Dictionary column names must be non-empty and unique.", call. = FALSE)
    }
    missing <- setdiff(c("MedCodeId", "Term", "Observations"), names(dict))
    if (length(missing)) {
        stop("Missing required column(s): ", paste(missing, collapse = ", "),
             call. = FALSE)
    }
    check_text(dict[["MedCodeId"]], "MedCodeId", empty = TRUE)
    counts <- trimws(dict[["Observations"]])
    counts[counts %in% c("", "NA")] <- NA_character_
    observations <- suppressWarnings(as.numeric(counts))
    invalid <- !is.na(counts) & (is.na(observations) | !is.finite(observations) |
                               observations < 0 | observations != floor(observations))
    if (any(invalid)) {
        stop("'Observations' must contain non-negative whole numbers or missing values.",
             call. = FALSE)
    }
    data.table::set(dict, j = "Observations", value = observations)
    data.table::set(dict, j = "term_lower", value = tolower(dict[["Term"]]))
    .cprd_env$dictionary <- dict
    .cprd_env$filepath <- filepath
    message("Loaded ", nrow(dict), " medical terms.")
    invisible(data.table::copy(dict))
}

get_dictionary <- function() {
    if (!exists("dictionary", envir = .cprd_env, inherits = FALSE)) {
        stop("Dictionary not loaded. Run load_cprd_dictionary() first.", call. = FALSE)
    }
    .cprd_env$dictionary
}
