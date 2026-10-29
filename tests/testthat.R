if (requireNamespace("testthat", quietly = TRUE) &&
    requireNamespace("withr", quietly = TRUE)) {
    library(testthat)
    library(cprd.search)
    test_check("cprd.search")
}
