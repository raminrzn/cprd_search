test_that("loading preserves identifiers, types, and private cache state", {
    path <- local_dictionary()
    dict <- load_cprd_dictionary(path)
    expect_s3_class(dict, "data.table")
    expect_identical(dict$MedCodeId, sprintf("%05d", 1:6))
    expect_identical(dict$SnomedCTConceptId[1], "9007199254740993")
    expect_type(dict$Observations, "double")
    data.table::set(dict, i = 1L, j = "Term", value = "changed")
    expect_identical(cprd_search("diabetes")$Term[1], "diabetes")
    expect_identical(load_cprd_dictionary()$Term[1], "diabetes")
})

test_that("explicit new paths reload and force refreshes the same path", {
    path <- local_dictionary()
    data <- synthetic_dictionary()
    data$Term[1] <- "updated"
    utils::write.table(data, path, sep = "\t", quote = FALSE, row.names = FALSE)
    expect_identical(load_cprd_dictionary(path)$Term[1], "diabetes")
    expect_identical(load_cprd_dictionary(path, force = TRUE)$Term[1], "updated")
    new_path <- tempfile()
    withr::defer(unlink(new_path))
    data$Term[1] <- "new file"
    utils::write.table(data, new_path, sep = "\t", quote = FALSE, row.names = FALSE)
    expect_identical(load_cprd_dictionary(new_path)$Term[1], "new file")
    expect_error(load_cprd_dictionary(paste0(path, ".missing")), "File not found")
    expect_identical(cprd_search("new file")$Term, "new file")
})

test_that("invalid dictionary files do not replace a valid cache", {
    path <- local_dictionary()
    bad <- synthetic_dictionary()
    bad$Observations <- NULL
    utils::write.table(bad, path, sep = "\t", quote = FALSE, row.names = FALSE)
    expect_error(load_cprd_dictionary(path, force = TRUE), "Missing required.*Observations")
    expect_identical(ids(cprd_search("asthma")), "00005")
    for (value in c("bad", "-1", "0.5", "Inf")) {
        bad <- synthetic_dictionary()
        bad$Observations[1] <- value
        utils::write.table(bad, path, sep = "\t", quote = FALSE, row.names = FALSE)
        expect_error(load_cprd_dictionary(path, force = TRUE), "Observations")
    }
    bad <- synthetic_dictionary()
    bad$MedCodeId[1] <- ""
    utils::write.table(bad, path, sep = "\t", quote = FALSE, row.names = FALSE)
    expect_error(load_cprd_dictionary(path, force = TRUE), "MedCodeId")
})

test_that("minimal and empty dictionaries are supported", {
    minimal <- synthetic_dictionary()[, c("MedCodeId", "Term", "Observations")]
    local_dictionary(minimal[FALSE, ])
    result <- cprd_search("asthma")
    expect_s3_class(result, "tbl_df")
    expect_identical(names(result), names(minimal))
    expect_identical(result$MedCodeId, character())
    expect_identical(result$Observations, numeric())
    expect_equal(nrow(cprd_search_fuzzy("asthma")), 0L)
})

test_that("truncated or ragged files cannot silently replace the cache", {
    path <- local_dictionary()
    writeLines(c("MedCodeId\tTerm\tObservations", "1\tdiabetes\t1",
                 "2\tasthma", "3\tcancer\t3"), path)
    expect_error(load_cprd_dictionary(path, force = TRUE), "Cannot read dictionary completely")
    expect_identical(ids(cprd_search("asthma")), "00005")
})

test_that("numeric-looking code columns retain leading zeroes", {
    data <- synthetic_dictionary()
    data$CleansedReadCode <- sprintf("%05d", 1:6)
    local_dictionary(data)
    expect_identical(cprd_search("00001", column = "CleansedReadCode")$CleansedReadCode,
                     "00001")
})

test_that("file and force arguments are checked", {
    local_dictionary(load = FALSE)
    expect_error(load_cprd_dictionary("nonexistent-file.txt"), "File not found")
    expect_error(load_cprd_dictionary(tempdir()), "File not found")
    for (bad in list(NA_character_, "", character(), c("a", "b"), 1)) {
        expect_error(load_cprd_dictionary(bad), "filepath")
    }
    expect_error(load_cprd_dictionary(force = NA), "force")
})
