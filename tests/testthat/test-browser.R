test_that("browser query parsing handles lower-case OR and exclusions", {
    local_dictionary()
    expect_identical(ids(browse_query("or: asthma, diabetes", 0)), c("00001", "00002", "00005"))
    expect_identical(ids(browse_query("Diabetes -gestational", 0)), "00001")
    expect_identical(ids(browse_query("lung cancer", 0)), c("00004", "00006"))
})

test_that("browser prints actual tibble results and recovers from bad input", {
    local_dictionary()
    answers <- c("", "asthma", "-gestational", "or: diabetes, asthma", "q")
    i <- 0L
    input <- function(prompt) {
        i <<- i + 1L
        if (i > length(answers)) stop("Unexpected extra prompt")
        answers[i]
    }
    output <- paste(capture.output(browse_loop(0, input)), collapse = "\n")
    expect_match(output, "asthma")
    expect_match(output, "diabetes")
    expect_match(output, "Error: 'include'")
    expect_false(grepl("could not find function|export_cols", output))
    expect_identical(i, length(answers))
    noninteractive_browser <- cprd_browse
    environment(noninteractive_browser) <- list2env(
        list(interactive = function() FALSE), parent = environment(cprd_browse)
    )
    expect_error(noninteractive_browser(), "interactively")
})
