# cprd.search

Search a user-supplied Clinical Practice Research Datalink (CPRD) Aurum medical
dictionary and assemble candidate medical code lists. Results are tibbles;
identifiers remain character strings so long codes and leading zeroes are preserved.

## Installation

The package is being prepared for its first CRAN submission. Install the
GitHub version with its dependencies:

```r
install.packages("remotes")
remotes::install_github("raminrzn/cprd_search")
```

From a local checkout, use `remotes::install_local("path/to/cprd_search")`.

## Try it with synthetic data

This example runs without access to CPRD. All six rows, identifiers and counts
in the bundled fixture are fabricated and must not be used as clinical codes.

```r
library(cprd.search)
path <- system.file("extdata", "synthetic-dictionary.tsv", package = "cprd.search")
load_cprd_dictionary(path)

# All keywords / any keyword / exclusions
cprd_search("family history", "lung cancer")
cprd_search_or("asthma", "diabetes")
cprd_search_exclude("diabetes", exclude = "gestational")

# Select columns and combine overlapping searches
first <- cprd_search("diabetes", select = c("MedCodeId", "Term"))
second <- cprd_search("asthma", select = c("MedCodeId", "Term"))
codes <- cprd_combine(first, second)

# Export, then read identifiers explicitly as character
file <- tempfile(fileext = ".csv")
cprd_export(codes, file)
utils::read.csv(file, colClasses = "character")
unlink(file)
```

For a real dictionary, obtain the file through your CPRD access arrangements
(see [CPRD](https://www.cprd.com/)) and call
`load_cprd_dictionary("path/to/CPRDAurumMedical.txt")`. No real dictionary or
patient data is distributed with the package. Searches produce candidates for
review, not validated study phenotypes.

## Matching and filtering

Keyword matching is case-insensitive and **literal by default**. Punctuation in
Read codes, including dots, is not a wildcard. Set `regex = TRUE` explicitly to
use regular expressions.

```r
cprd_search("H33..", column = "CleansedReadCode")
cprd_search("^asthma$", regex = TRUE)
cprd_search("diabetes", min_obs = 50, select = c("MedCodeId", "Term"))
```

AND, OR and exclusion searches accept `column`, `regex`, `min_obs` and `select`.
`column` may name any loaded column, including `EmisCodeCategoryId`; matching
is by substring, so use an anchored regular expression for an exact category.
Fuzzy search always uses `Term`. A positive `min_obs` excludes missing counts;
zero includes them and places them last when sorting.

## Fuzzy matching

Fuzzy search compares **complete descriptions**, not individual words. Its
default is optimal string alignment (`method = "osa"`) with at most two edits.
There is no prefix filter, so misspellings at the start of a term can match.

```r
cprd_search_fuzzy("diabeties", select = c("MedCodeId", "Term", "dist"))
cprd_search_fuzzy("xiabetes", max_dist = 1)
cprd_search_fuzzy("diabeties", method = "jw", max_dist = 0.1)
```

For normalized methods (`jw`, `cosine`, `jaccard`), the default threshold is
0.1 and must be within 0–1. Longer descriptions can require larger edit
thresholds. Results are sorted by distance then observation count and capped
at `max_results = 50`. Zero results still returns a tibble with its column types.

## Dictionary format and cache

Files must be tab-delimited with `MedCodeId`, `Term` and `Observations` columns.
Standard additional columns are `OriginalReadCode`, `CleansedReadCode`,
`SnomedCTConceptId`, `SnomedCTDescriptionId`, `Release` and `EmisCodeCategoryId`.
Counts must be non-negative whole numbers or missing; other fields are read as
character. This preserves leading zeroes and identifiers longer than R's exact
numeric integer range. Explicitly retain character types when opening exports
in other software as well.

Repeated loads of the same path reuse the cache; `force = TRUE` reloads a changed
file. An explicit different path switches dictionaries. A failed load leaves
the previous dictionary intact. Editing the returned table does not mutate the
cached dictionary.

`cprd_combine()` keeps the first row for each `MedCodeId`, fills absent columns
with missing values, and sorts by `Observations` when that column is present.
Without that column, it preserves input order.

## Interactive browsing and further help

In an interactive R console, run `cprd_browse()`. Enter space-separated keywords,
`OR: asthma, diabetes`, or `diabetes -gestational`; type `q` to quit.
See `vignette("search-workflow", package = "cprd.search")` for a complete workflow.

## Development

```r
install.packages(c("devtools", "roxygen2"))
devtools::document()
devtools::test()
devtools::check(args = "--as-cran")
```

GitHub Actions checks R-release on Linux, macOS and Windows, plus R-devel and
R-oldrel on Linux. The Linux release check also builds the PDF manual. Tests
and examples use only synthetic data and temporary export files.

## License

MIT. See [LICENSE.md](LICENSE.md).
