## Resubmission of cprd.search 0.1.1

This resubmission addresses Uwe Ligges's feedback of 2026-10-19:

> Found the following (possibly) invalid file URI: LICENSE.md, from README.md.
> Please fix and resubmit.

The README now links to the public full license text at
https://github.com/raminrzn/cprd_search/blob/main/LICENSE.md, rather than a
relative file omitted from the source package. The version is increased from
0.1.0 to 0.1.1. Package R code and the 167 synthetic-data test assertions are
unchanged.

## Link validation

The exact built source archive is scanned independently for Markdown and HTML
links, local files and anchors, and external URLs in source and help files.
This audit reproduces the original 0.1.0 failure and passes for the revised
archive. The release workflow requires this check before publishing the
submission bundle; the checkout is not used to resolve file targets.

The CPRD homepage https://www.cprd.com/ returns HTTP 403 to automated HEAD and
GET requests from this machine. It was verified in a normal browser on
2026-10-19 and displays the Clinical Practice Research Datalink homepage.
The audit records this explicit exception; it does not ignore other failures.
All three distinct GitHub URLs, including the replacement license URL, return
HTTP 200.

## Check results

Checks completed on 2026-10-19 with no errors or warnings:

- Linux, Windows and macOS with R 4.6.1; Linux with R 4.5.3 and
  R-devel (2026-10-18 r90707).
- Full Linux release check, including PDF and HTML manuals, examples and vignette.
- The exact R 4.6.1-built source archive checked on R-devel without rebuilding.
- All six jobs pass 167 assertions with no failures, test warnings or skips.
- Incoming-enabled checks report only New submission; the other checks are OK.
- Archive link audit: 30 documents, 119 local file/anchor references, four
  distinct external URLs, no unresolved link errors. The CPRD exception above
  remains explicit in the audit report.

Workflow: https://github.com/raminrzn/cprd_search/actions/runs/39288407755
Checked source: 629fb9c17aa535aaa23f0e2902d7804cb9bcdf32
Archive SHA-256: 4d74a6c42a951e73772e31343887b0884e4250c18d757034a5ac0bf8c95305da

The terms Aurum, CPRD and Datalink are the data provider's proper names and
abbreviation; deduplicated describes combining results without duplicate codes.
Only fabricated example dictionary data are distributed. Tests, examples and
the vignette need no CPRD account, real dictionary, patient data or network.
