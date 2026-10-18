test_that("fuzzy matches include prefix typos and exclude unrelated terms", {
    local_dictionary()
    expect_identical(ids(cprd_search_fuzzy("diabeties")), "00001")
    result <- cprd_search_fuzzy("xiabetes", max_dist = 1)
    expect_identical(ids(result), "00001")
    expect_equal(result$dist, 1)
    expect_identical(ids(cprd_search_fuzzy("DIABETES", max_dist = 0)), "00001")
    expect_identical(ids(cprd_search_fuzzy("diabeties", method = "jw")), "00001")
    expect_identical(ids(cprd_search_fuzzy("diabeties", method = "jw", max_dist = 0.1)), "00001")
    expect_equal(nrow(cprd_search_fuzzy("diabeties", min_obs = 101)), 0L)
})

test_that("fuzzy results use whole descriptions, consistent columns, and safe limits", {
    local_dictionary()
    full <- cprd_search_fuzzy("diabeties")
    expect_false("00002" %in% ids(full))
    for (empty in list(cprd_search_fuzzy("zzzzzzzz", max_dist = 0),
                       cprd_search_fuzzy("diabeties", max_results = 0))) {
        expect_equal(nrow(empty), 0L)
        expect_s3_class(empty, "tbl_df")
        expect_identical(names(empty), names(full))
        expect_identical(vapply(empty, typeof, ""), vapply(full, typeof, ""))
    }
    expect_equal(nrow(cprd_search_fuzzy("diabetes", max_dist = 100, max_results = 2)), 2L)
    selected <- cprd_search_fuzzy("diabeties", select = c("MedCodeId", "dist"))
    expect_identical(names(selected), c("MedCodeId", "dist"))
    expect_error(cprd_search_fuzzy("diabeties", select = "missing"), "Unknown column")
})

test_that("fuzzy distance ties are sorted by observations and skip missing terms", {
    data <- synthetic_dictionary()
    data$Term <- c("cat", "bat", "hat", "", "mat", "dog")
    data$Observations <- c("10", "30", NA, "200", "20", "50")
    local_dictionary(data)
    expect_identical(ids(cprd_search_fuzzy("cat", max_dist = 1)), c("00001", "00002", "00005", "00003"))
})

test_that("fuzzy arguments and normalized thresholds are validated", {
    local_dictionary()
    for (bad in list("", NA_character_, c("a", "b"), 2)) {
        expect_error(cprd_search_fuzzy(bad), "term")
    }
    for (method in c("jw", "cosine", "jaccard")) {
        expect_error(cprd_search_fuzzy("diabetes", method = method, max_dist = 2), "between 0 and 1")
    }
    expect_error(cprd_search_fuzzy("diabetes", method = "bad"), "Unknown distance")
    expect_error(cprd_search_fuzzy("diabetes", max_dist = NA), "max_dist")
    expect_error(cprd_search_fuzzy("diabetes", max_results = -1), "max_results")
    expect_error(cprd_search_fuzzy("diabetes", max_results = 0.5), "max_results")
})
