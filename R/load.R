#' Load the CPRD Aurum Medical Dictionary
#'
#' Reads the CPRD Aurum Medical Dictionary from a tab-delimited text file
#' and stores it in memory for fast searching.
#'
#' @param filepath Character string. Path to the CPRDAurumMedical.txt file.
#'   If NULL (default), looks for the file in the current working directory.
#' @param force Logical. If TRUE, reload the dictionary even if already loaded.
#'   Default is FALSE.
#'
#' @return A \code{data.table} with the full CPRD Aurum Medical Dictionary
#'   (returned invisibly).
#'
#' @details The dictionary is cached in memory after the first load, so
#'   subsequent calls are instant. Use \code{force = TRUE} to reload.
#'
#'   The file should be the standard CPRD Aurum Medical Dictionary with columns:
#'   MedCodeId, Observations, OriginalReadCode, CleansedReadCode, Term,
#'   SnomedCTConceptId, SnomedCTDescriptionId, Release, EmisCodeCategoryId.
#'
#' @examples
#' \dontrun{
#' # Load from default location
#' dict <- load_cprd_dictionary("path/to/CPRDAurumMedical.txt")
#'
#' # Check how many terms are loaded
#' nrow(dict)
#' }
#'
#' @export
load_cprd_dictionary <- function(filepath = NULL, force = FALSE) {

    # Return cached version if available
    if (!force && exists("dictionary", envir = .cprd_env)) {
        message("Dictionary already loaded (",
                format(nrow(.cprd_env$dictionary), big.mark = ","),
                " terms). Use force = TRUE to reload.")
        return(invisible(.cprd_env$dictionary))
    }

    # Try to find the file
    if (is.null(filepath)) {
        candidates <- c(
            "CPRDAurumMedical.txt",
            file.path("inst", "extdata", "CPRDAurumMedical.txt"),
            file.path("data-raw", "CPRDAurumMedical.txt")
        )
        found <- candidates[file.exists(candidates)]
        if (length(found) == 0) {
            stop("Cannot find CPRDAurumMedical.txt. Please provide the filepath argument.",
                 call. = FALSE)
        }
        filepath <- found[1]
    }

    if (!file.exists(filepath)) {
        stop("File not found: ", filepath, call. = FALSE)
    }

    message("Loading CPRD Aurum Medical Dictionary from:\n  ", filepath)

    # Read the tab-delimited file
    dict <- data.table::fread(filepath, sep = "\t", header = TRUE,
                               quote = "", fill = TRUE,
                               encoding = "UTF-8")

    # Create a lowercase version of Term for faster searching
    dict[, term_lower := tolower(Term)]

    # Store in package environment
    assign("dictionary", dict, envir = .cprd_env)

    message("Loaded ", format(nrow(dict), big.mark = ","), " medical terms.")
    invisible(dict)
}


#' Get the loaded CPRD dictionary
#'
#' Internal helper to retrieve the cached dictionary, with a helpful
#' error message if it hasn't been loaded yet.
#'
#' @return A \code{data.table} with the CPRD dictionary.
#' @keywords internal
get_dictionary <- function() {
    if (!exists("dictionary", envir = .cprd_env)) {
        stop("Dictionary not loaded. Run load_cprd_dictionary() first.",
             call. = FALSE)
    }
    .cprd_env$dictionary
}
