# CRAN release checklist

- [x] Correct functional defects and add synthetic-data regression tests.
- [x] Build using current R 4.6.1 and check the exact tarball on R-devel.
- [x] Pass Linux, macOS, Windows and R-oldrel checks, with 167 assertions per run.
- [x] Validate both the PDF and HTML manuals; run all noninteractive examples
  and the workflow vignette.
- [x] Confirm no name collision in current/archived CRAN or current Bioconductor.
- [x] Record check environments and the expected new-submission NOTE in
  cran-comments.md. Keep these release notes outside the source package.
- [x] Save the checked source tarball and checksum in the CI submission artifact.
- [ ] Review and merge PR #1.
- [ ] Submit the checked tarball through https://cran.r-project.org/submit.html
  and accept the confirmation email sent to ramin.rezaeianzadeh@outlook.com.

Use the CRAN-submission-bundle artifact from workflow run 39165427255.
If package contents change, rebuild and repeat the release checks before
submitting. The current candidate has not been submitted or merged.
