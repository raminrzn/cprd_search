test_that("search functions require a loaded dictionary", {
    local_dictionary(load = FALSE)
    expect_error(cprd_search("test"), "Dictionary not loaded")
    expect_error(cprd_search_or("test"), "Dictionary not loaded")
    expect_error(cprd_search_exclude("test"), "Dictionary not loaded")
    expect_error(cprd_search_fuzzy("test"), "Dictionary not loaded")
})

test_that("AND, OR, exclusion, and observation filters return expected codes", {
    local_dictionary()
    expect_identical(ids(cprd_search("FAMILY HISTORY", "LUNG CANCER")), "00004")
    expect_identical(ids(cprd_search(c("family history", "cancer"))), "00004")
    expect_identical(ids(cprd_search_or("asthma", "lung cancer")), c("00004", "00005", "00006"))
    expect_identical(ids(cprd_search_exclude("diabetes", "gestational")), "00001")
    expect_identical(ids(cprd_search_exclude(c("diabetes", "asthma"), "gestational",
                                            or_logic = TRUE)), c("00001", "00005"))
    expect_identical(ids(cprd_search("diabetes", min_obs = 75)), "00001")
    expect_identical(ids(cprd_search_or("asthma", "diabetes", min_obs = 50)), c("00001", "00002"))
    expect_identical(ids(cprd_search_exclude("H33", "X1", column = "CleansedReadCode")), "00005")
})

test_that("literal punctuation and opt-in regex are consistent", {
    data <- synthetic_dictionary()
    data$Term[1] <- "diabetes (review)"
    local_dictionary(data)
    expect_identical(ids(cprd_search("H33..", column = "CleansedReadCode")), "00005")
    expect_identical(ids(cprd_search("H33..", column = "CleansedReadCode", regex = TRUE)),
                     c("00005", "00006"))
    expect_identical(ids(cprd_search("(")), "00001")
    expect_identical(ids(cprd_search_or("(", "asthma")), c("00001", "00005"))
    expect_identical(ids(cprd_search_exclude("diabetes", "(")), "00002")
    expect_identical(ids(cprd_search("^asthma$", regex = TRUE)), "00005")
    expect_equal(nrow(cprd_search("\\D", column = "MedCodeId", regex = TRUE)), 0L)
    expect_error(cprd_search("(", regex = TRUE), "Invalid regular expression")
})

test_that("selection and empty results preserve the result contract", {
    local_dictionary()
    result <- cprd_search("diabetes", select = c("Term", "MedCodeId"))
    empty <- cprd_search("no such term", select = c("Term", "MedCodeId"))
    expect_identical(names(result), c("Term", "MedCodeId"))
    expect_s3_class(empty, "tbl_df")
    expect_identical(names(empty), names(result))
    expect_identical(vapply(empty, typeof, ""), vapply(result, typeof, ""))
    expect_false("term_lower" %in% names(cprd_search("diabetes")))
    expect_error(cprd_search("diabetes", select = "bad"), "Unknown column")
    expect_error(cprd_search("diabetes", select = c("Term", "Term")), "duplicates")
    expect_error(cprd_search("diabetes", column = "bad"), "not found")
})

test_that("missing descriptions and counts have defined filtering and ordering", {
    data <- synthetic_dictionary()
    data$Term[2] <- ""
    data$Observations[1] <- NA_character_
    local_dictionary(data)
    expect_identical(ids(cprd_search_or("diabetes", "asthma")), c("00005", "00001"))
    expect_identical(ids(cprd_search_or("diabetes", "asthma", min_obs = 1)), "00005")
    expect_identical(ids(cprd_search(".*", regex = TRUE)), c("00003", "00004", "00005", "00006", "00001"))
})

test_that("invalid keywords and parameters fail clearly", {
    local_dictionary()
    expect_error(cprd_search(), "at least one keyword")
    expect_error(cprd_search_or(), "at least one keyword")
    for (bad in list("", " ", NA_character_, character(), 1)) {
        expect_error(cprd_search(bad), "keywords")
        expect_error(cprd_search_or(bad), "keywords")
        expect_error(cprd_search_exclude(bad), "include")
    }
    expect_error(cprd_search_exclude("diabetes", NA_character_), "exclude")
    for (bad in list(NA_real_, -1, Inf, 1.5, c(1, 2), "2")) {
        expect_error(cprd_search("diabetes", min_obs = bad), "min_obs")
    }
    expect_error(cprd_search("diabetes", regex = NA), "regex")
    expect_error(cprd_search_exclude("diabetes", or_logic = 1), "or_logic")
    expect_error(cprd_search("diabetes", column = c("Term", "MedCodeId")), "column")
})
