#' Search the Clinical Practice Research Datalink Aurum Dictionary
#'
#' Load a user-supplied dictionary with [load_cprd_dictionary()], search with
#' [cprd_search()], [cprd_search_or()], [cprd_search_exclude()], or
#' [cprd_search_fuzzy()], combine with [cprd_combine()], and save with
#' [cprd_export()]. [cprd_browse()] provides an interactive console.
#'
#' Only synthetic example data is included. Real CPRD dictionary files must be
#' obtained separately. Search results are candidates for review, not validated
#' study phenotypes.
#' @import data.table
"_PACKAGE"

.cprd_env <- new.env(parent = emptyenv())
