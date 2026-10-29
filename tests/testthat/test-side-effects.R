test_that("export without an explicit path cannot create or overwrite a file", {
    local_dictionary()
    results <- cprd_search("diabetes")
    workspace <- withr::local_tempdir()
    withr::local_dir(workspace)

    expect_error(cprd_export(results), "filename.*supplied explicitly")
    expect_identical(list.files(all.files = TRUE, no.. = TRUE), character())

    # This is the old default filename: a missing argument must not overwrite it.
    sentinel <- "cprd_search_results.csv"
    writeLines("existing user data", sentinel)
    before <- readBin(sentinel, "raw", n = file.info(sentinel)$size)
    expect_error(cprd_export(results), "filename.*supplied explicitly")
    expect_identical(readBin(sentinel, "raw", n = file.info(sentinel)$size), before)

    for (bad in list(NULL, "", " ", NA_character_, character(), c("a", "b"), 1)) {
        expect_error(cprd_export(results, filename = bad), "filename")
    }
    expect_identical(list.files(all.files = TRUE, no.. = TRUE), sentinel)
    expect_identical(readLines(sentinel), "existing user data")
})

test_that("export writes only the caller's chosen path", {
    local_dictionary()
    workspace <- withr::local_tempdir()
    withr::local_dir(workspace)
    path <- tempfile(fileext = ".csv")
    withr::defer(unlink(path))
    results <- cprd_search("diabetes")
    expect_identical(cprd_export(results, filename = path), path)
    expect_true(file.exists(path))
    expect_identical(list.files(all.files = TRUE, no.. = TRUE), character())
    expect_identical(utils::read.csv(path, colClasses = "character")$MedCodeId,
                     results$MedCodeId)
})

test_that("dictionary operations preserve the user's session and files", {
    path <- local_dictionary()
    # Warm up dependency namespaces before recording user-visible state.
    cprd_combine(cprd_search("diabetes"), cprd_search_fuzzy("diabeties"))
    workspace <- withr::local_tempdir()
    withr::local_dir(workspace)
    before <- list(wd = getwd(), options = options(), search = search(),
                   globals = ls(.GlobalEnv, all.names = TRUE),
                   threads = data.table::getDTthreads())
    load_cprd_dictionary(path, force = TRUE)
    a <- cprd_search("diabetes")
    b <- cprd_search_or("asthma", "diabetes")
    cprd_search_exclude("diabetes", "gestational")
    cprd_search_fuzzy("diabeties")
    cprd_combine(a, b)
    expect_identical(getwd(), before$wd)
    expect_identical(options(), before$options)
    expect_identical(search(), before$search)
    expect_identical(ls(.GlobalEnv, all.names = TRUE), before$globals)
    expect_identical(data.table::getDTthreads(), before$threads)
    expect_identical(list.files(all.files = TRUE, no.. = TRUE), character())
})
