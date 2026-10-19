# cprd.search 0.1.1

* Replace the README's relative license link with the public full license URL,
  so it works when LICENSE.md is excluded from the CRAN source archive.
* Audit links in the built submission archive as part of the release workflow.

# cprd.search 0.1.0

Initial CRAN release candidate.

* Search, combine, export and browser functions consistently support tibble results.
* Keyword matching is literal by default; `regex = TRUE` opts into patterns.
  Exclusion searches now also accept a `column` argument.
* Fuzzy search compares complete descriptions, defaults to optimal string
  alignment, uses method-appropriate thresholds, and retains prefix misspellings.
* Empty results retain their columns and types; zero result limits are supported.
* Dictionary loading validates required columns and observation counts, preserves
  identifiers as character, and keeps the previous cache when a load fails.
* Combining selected results no longer requires an Observations column.
* Added synthetic-data tests, runnable examples, a workflow vignette, and
  automated package checks across operating systems and R versions.
