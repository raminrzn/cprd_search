# CRAN policy audit — cprd.search 0.1.2

Reviewed 29 October 2026 against:

* [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html)
* [Submission checklist](https://cran.r-project.org/web/packages/submission_checklist.html)
* [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html),
  especially package structure, dependencies, checking, documentation and portability
* [URL checks](https://cran.r-project.org/web/packages/URL_checks.html)

This is a review of the complete package sources and the built archive, not
an assurance of acceptance. CRAN's manual assessment remains authoritative.

## Findings and fixes

1. `cprd_export()` defaulted to `cprd_search_results.csv`, allowing a call with
   no output path to write into the working directory. Removed that default:
   `filename` is mandatory, with a clear error before any file is opened.
   Documentation states that the caller selects the path and existing files
   at that explicit path are overwritten.
2. Tests used suggested testing packages unconditionally. The test entry point
   now checks availability of both testthat and withr. Normal checks still run
   every test; users without suggested packages can load and use the package.
3. No further source defects were identified by the review below. The previous
   license-link correction remains in place.

## Review coverage and evidence

| Area | Package evidence and verification |
| --- | --- |
| Authorship, copyright and licensing | DESCRIPTION identifies Ramin Rezaeianzadeh as author and sole maintainer with the confirmed Outlook address. MIT template LICENSE and full public license agree. All bundled fixture rows are fabricated. No third-party code or real CPRD data is bundled. |
| Name, title and description | Existing submission name retained. Title and description explain dictionary searching, output and separate CPRD access. No unsupported clinical validation claim, promotional language or development-version dependency. Provider name and abbreviations explained. |
| Dependencies | data.table, stringdist and tibble are declared Imports and used. Testing/vignette dependencies are Suggests. No undeclared runtime dependency, installation download or restrictive external software. Imported dependency licenses are MPL-2.0, GPL-3 and MIT respectively. |
| Startup and namespace | No startup/attachment hook, installation script, network operation or file write. The only top-level R assignment creates a private empty cache. Eight exports are documented. No global workspace assignment or change to another package's namespace in distributed code. |
| File writes and cleanup | Export is the sole runtime writer and requires a caller-supplied path. Every bundled example, vignette and test write resolves into tempdir(); temporary fixture/export files are removed. New regression tests cover omitted/invalid paths, the old default filename as a sentinel, explicit export destination and unchanged user files. |
| Session state | Loader/search/combine cache only inside the package environment. Regression checks cover working directory, options, search path, global binding names and data.table thread setting. Test helper defers cache and working-directory restoration. |
| Processes, viewers and network | No runtime downloads, telemetry, subprocesses, clipboard access, credential requests or network dependency. Browser export requires both explicit open=TRUE and an interactive session. Console browser is interactive-only; its example is guarded. Automated execution must launch neither viewer nor download. |
| CPU and resources | Dictionary fread and stringdist calls specify one thread. Tests use six synthetic rows. CI limits OpenMP threads to two. No cluster, parallel worker, huge fixture or long-running example. |
| Portability and encoding | Pure R; no compiled source, executables, platform-specific scripts or system requirement. UTF-8 declared; CSV round-trip test includes non-ASCII text. Paths use system.file(), tempfile() and file.path(). CI covers Windows/macOS/Linux and release/devel/oldrel R. |
| Public APIs | No .Internal(), native entry point, base-package ::: access, SSL bypass, stack-check modification or process termination. Dependencies are called through their public interfaces. |
| Documentation and examples | Roxygen source and generated Rd agree, including the required filename. Examples run using included synthetic data. Interactive example is conditional. Vignette and installed example script exercise the complete search/combine/export workflow without external data or connectivity. |
| Archive contents and size | Inspect the exact R CMD build archive, excluding maintainer scripts, CI, CRAN correspondence and this report. Include vignette source alongside generated HTML, readable R/tests and the tiny TSV. No hidden credentials, user data, binary executable or unexplained generated artifact. Record archive size and hash after final build. |
| Links | Existing archive audit resolves local files and anchors using archive members. Checks every distinct external URL, including the public full-license URL. CPRD's homepage returns 403 to automated clients; require browser verification and disclose this exception rather than silently suppressing failures. |
| Submission and version | Increase to 0.1.2. Record reviewer feedback and response in the web-form comment. Submit only the checked release-built archive, then complete the maintainer confirmation. No reverse dependencies were reported for this unpublished package. |

## Release gates

* Run all tests and R CMD check --as-cran across the platform/R matrix, with
  PDF/HTML manuals, examples and rebuilt vignette included where supported.
* Recheck the exact release-built tarball on current R-devel without rebuilding.
* Run the independent link audit on that same archive.
* Install that archive with tests into a temporary library. Execute all nine
  help pages (eight contain example blocks), the installed example script, vignette code and full
  installed test suite while intercepting the file operations used by this
  package and its tests. Reject paths outside tempdir(), viewer launches and
  downloads. This supplements source review; it is not a general R sandbox.
* Preserve final check logs, link report, source revision and archive SHA-256
  alongside the delivered audit and submission receipt.
