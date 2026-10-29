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

## Completed validation

Checks completed on 29 October 2026 with no errors or warnings:

* Linux R 4.6.2, Windows/macOS R 4.6.1, Linux R 4.5.3 and R-devel
  (2026-10-26 r90766).
* Full Linux release check, including PDF/HTML manuals, examples and rebuilt vignette.
* Exact R 4.6.2-built source archive rechecked on R-devel without rebuilding.
* All six jobs pass 190 assertions with zero failures, warnings or skips.
* Incoming-enabled checks report only New submission; the other checks are OK.
* File-write audit: eight help example blocks, installed example script, vignette
  code and installed tests; all 776 observed operations remain in tempdir(),
  package source/installation remain read-only, and no viewer/download is invoked.
* Link audit: 31 documents, 119 local file/anchor references and four external
  URLs, with no unresolved errors. Three GitHub URLs return HTTP 200. CPRD's
  homepage returns HTTP 403 to automated HEAD/GET but was verified in a normal
  browser on 29 October 2026; this explicit exception is retained in the report.

Archive: 25,790 compressed bytes; 36 files, 97,875 unpacked bytes; no executable
file modes or maintainer-only files. Vignette source and generated HTML are present.

The regression negative control reproduced the old default-name overwrite using
0.1.1 code entirely within tempdir(); 0.1.2 raises an error and preserves the sentinel.
A local dependencies-only check also passed (vignette checks disabled); its only
NOTE concerned the sandbox's inability to verify the system clock.

Workflow: https://github.com/raminrzn/cprd_search/actions/runs/40954344406

Checked source: 7df3b6f5dc62bbfe3096d5635db9e47552a9a764

Archive SHA-256: 610168a1da7b298ae9dced9a1a188579346dd9ec69bf88380bddb86ac103b655
