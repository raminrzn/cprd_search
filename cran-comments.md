## Submission

This is the first submission of cprd.search, which searches user-supplied
Clinical Practice Research Datalink Aurum medical dictionaries. Only an entirely
fabricated six-row dictionary is included. Examples, tests and the vignette
require no CPRD account, real dictionary, patient data, or network access.

## Test environments and results

Checks completed on 2026-10-18 with no errors or warnings:

- Ubuntu 24.04.5, R 4.6.1: `R CMD check --as-cran`, including CRAN incoming
  checks and both PDF and HTML manual validation. One NOTE: New submission.
- Windows Server 2022 x64, R 4.6.1 ucrt: `--as-cran --no-manual`, Status: OK.
- macOS Tahoe 26.6.2 arm64, R 4.6.1: `--as-cran --no-manual`, Status: OK.
- Ubuntu 24.04.5, R 4.5.3: `--as-cran --no-manual`, Status: OK.
- Ubuntu 24.04.5, R-devel (2026-10-16 r90685): `--as-cran --no-manual`, Status: OK.
- The exact source tarball built by R 4.6.1 was then checked, without rebuilding,
  on R-devel (2026-10-17 r90697) with `--as-cran --no-manual` and incoming checks
  enabled. One NOTE: New submission.

All environments pass 167 test assertions, with no failures, warnings or skips.
Examples and vignette checks also pass. Incoming checks are enabled in the
Linux release and final tarball checks, and disabled in the other matrix jobs.

## Notes

The sole NOTE in the two incoming-enabled checks is the expected first-submission
NOTE. There are no other outstanding package notes.

## Reproducibility

Workflow: https://github.com/raminrzn/cprd_search/actions/runs/39165427255
Checked source commit: 4da196aa73d52fbad3b1256aa40f90c57cebcf0b
The CRAN-submission-bundle workflow artifact contains the exact tarball,
its SHA-256 checksum, and the final R-devel check output.

The name cprd.search was checked, case-insensitively, against current CRAN,
archived CRAN, and current Bioconductor software on 2026-10-18; no collision
was found. This package has not yet been submitted to CRAN.
