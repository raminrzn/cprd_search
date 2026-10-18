test_that("selected results combine and overlapping codes deduplicate", {
    local_dictionary()
    a <- cprd_search("diabetes", select = c("MedCodeId", "Term"))
    b <- cprd_search_or("diabetes", "asthma", select = c("MedCodeId", "Term"))
    result <- cprd_combine(a, b)
    expect_identical(ids(result), c("00001", "00002", "00005"))
    expect_s3_class(result, "tbl_df")
    expect_identical(names(result), c("MedCodeId", "Term"))
    expect_equal(cprd_combine(a[FALSE, ], b), b)
    expect_equal(nrow(cprd_combine(a[FALSE, ], a[FALSE, ])), 0L)
    expect_identical(names(cprd_combine(a, select = "MedCodeId")), "MedCodeId")
})

test_that("combine keeps first duplicate and sorts available observations", {
    local_dictionary()
    a <- cprd_search("diabetes")
    b <- cprd_search_or("diabetes", "asthma")
    b$Term[1] <- "different label"
    expect_identical(cprd_combine(a, b)$Term[1], "diabetes")
    partial <- a[, c("MedCodeId", "Term")]
    combined <- cprd_combine(partial, b)
    expect_identical(ids(combined), c("00005", "00001", "00002"))
    expect_true(all(is.na(combined$Observations[-1])))
    expect_error(cprd_combine(), "at least one")
    expect_error(cprd_combine(data.frame(Term = "a")), "MedCodeId")
    expect_error(cprd_combine(data.frame(MedCodeId = NA_character_)), "MedCodeId")
    expect_error(cprd_combine(a, select = "bad"), "Unknown column")
})

test_that("CSV exports round-trip tibble, data.frame and data.table identifiers", {
    local_dictionary()
    results <- cprd_search_or("diabetes", "asthma")
    path <- tempfile(fileext = ".csv")
    withr::defer(unlink(path))
    for (input in list(results, as.data.frame(results), data.table::as.data.table(results))) {
        returned <- withVisible(cprd_export(input, path))
        expect_false(returned$visible)
        expect_identical(returned$value, path)
        reread <- utils::read.csv(path, colClasses = "character", check.names = FALSE)
        expect_identical(reread$MedCodeId, results$MedCodeId)
        expect_identical(reread$SnomedCTConceptId, results$SnomedCTConceptId)
        expect_identical(reread$EmisCodeCategoryId, results$EmisCodeCategoryId)
    }
    fuzzy <- cprd_search_fuzzy("diabeties")
    cprd_export(fuzzy, path)
    expect_false("dist" %in% names(utils::read.csv(path)))
    cprd_export(results[FALSE, ], path)
    expect_equal(nrow(utils::read.csv(path)), 0L)
    expect_error(cprd_export(list(), path), "data.frame")
    expect_error(cprd_export(results, NA_character_), "filename")
    expect_error(cprd_export(results, path, open = NA), "open")
})

test_that("CSV escaping and UTF-8 content survive export", {
    path <- tempfile(fileext = ".csv")
    withr::defer(unlink(path))
    input <- tibble::tibble(MedCodeId = "00001", Term = 'caf\u00e9, "review"')
    cprd_export(input, path)
    expect_equal(utils::read.csv(path, colClasses = "character", fileEncoding = "UTF-8")$Term,
                 input$Term)
})
