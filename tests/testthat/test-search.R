library(testthat)
library(cprd.search)

test_that("load_cprd_dictionary stops with missing file", {
    expect_error(load_cprd_dictionary("nonexistent.txt"),
                 "File not found")
})

test_that("search functions stop before dictionary is loaded", {
    # Clear any cached dictionary
    if (exists("dictionary", envir = cprd.search:::.cprd_env)) {
        rm("dictionary", envir = cprd.search:::.cprd_env)
    }
    expect_error(cprd_search("test"),
                 "Dictionary not loaded")
    expect_error(cprd_search_or("test"),
                 "Dictionary not loaded")
    expect_error(cprd_search_exclude(include = "test"),
                 "Dictionary not loaded")
    expect_error(cprd_search_fuzzy("test"),
                 "Dictionary not loaded")
})

test_that("cprd_search requires at least one keyword", {
    # First load a tiny test dictionary
    skip("Requires dictionary file")
})
