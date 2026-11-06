# Release review — 0.9.1

Starting revision: `0b36395` (published 0.9.0), clean working tree.
Release version: `0.9.1+21`. The user closed further exploration and requested
completion, commit, push and publication of the existing scope.

## Findings

- All three key probes could accept generic JSON without their expected
  payload. Require a usable TMDB image configuration or the requested probe
  identity for PoiskKino/OMDb. Three regressions returned `valid` before repair
  and now require `failed`; recorded successful probes remain supported.
- Settings dropdowns could consume a narrow ListTile's entire width at 2×
  text scaling, causing layout assertions in both locales. Put expanding,
  variable-height dropdowns under their labels. Tests exercise 320 dp at
  normal/large scale in English/Russian and change the navigation preference.
- Calendar formatting normalized impossible dates into other dates (for
  example 2023-02-29 into March 1). Reuse calendar validation before localized
  formatting. English/Russian regressions failed before repair and retain a
  valid leap day while omitting malformed dates.

- The separate calibration threshold query ran before opening the editor and
  could still escape the button callback, despite handling comparisons inside
  the editor. Fall back to an editor without comparisons. A real SQLite
  regression intercepts only COUNT queries, reproduces the failure and verifies
  that the draft can still be saved with its exact score/note.

- Rating-list comparators returned equality for different titles when all sort
  fields and score timestamps tied. Input-row order then changed the displayed
  order. Use the natural work key as the final tie-breaker. The regression
  compares reversed inputs across every sort mode and failed before repair.

- Drive metadata mapping dereferenced a missing ID and substituted empty
  strings for missing names/timestamps. Missing modification markers undermine
  the pre-write concurrency check. Reject missing required fields and map
  malformed timestamps to `SyncFailure.failed`. Four missing-field regressions
  failed before repair; list and metadata paths share validation. A separate
  invalid-date regression checks parsing failures.

- Rapid score changes back to the original value allowed the first lookup
  for that score to overwrite a later result. Guard publication by request
  revision as well as score and widget lifetime. The controlled-completion
  regression failed after observing the newer result replaced by the old one.
- A manual update check arriving in the same turn as a throttled automatic
  check shared its completed/no-network future and falsely reported current.
  Only share actual network checks. The concurrent manual/automatic regression
  failed before repair with `current` instead of `available`.

- Optional calibration lookup failures escaped the editor's unawaited callback
  as unhandled Flutter errors. Handle database lookup failures while retaining
  the draft and any previous comparison. The regression in
  `features/rating_note_test.dart` failed before the repair and checks that
  editing and saving remain available.

## Verification

Discover resume investigation: the user reported sections appearing again
after returning and scrolling stutter. Foreground changes rebuilt the candidate
stream, and its first empty batch replaced existing sections. A completed
people index also restarted and temporarily removed learned recommendation
sources. Retain completed streams; resume interrupted passes from the previous
pool for the same plan/client; skip fully loaded index passes. The retained
pool is a single bounded session snapshot, not persistent catalog storage.
`recommendation_resume_test.dart` covers complete and interrupted loads;
`people_index_test.dart` covers completed-index resumes. Phone frame-time
verification is pending: no physical device was connected when ADB was checked.

Source-rating presentation also treated future timestamps as fresh despite
the corrected service refresh policy. A pure cell-state regression reproduced
the mismatch; future ages now display as stale while keeping the value visible.

Version gate passed against `origin/main` (0.9.0+20 → 0.9.1+21).
First full verification of these changes passed: `make verify
TEST_ARGS='--reporter expanded'`, **556 passed**, **20 opt-in renderers skipped**;
formatting, analysis and version-script fixtures passed. Focused resume/editor
checks passed 36 tests plus both complete/interrupted resume scenarios.
Publication was subsequently explicitly requested by the user.

Second full cycle passed **565 tests**, with **20 opt-in renderers skipped**,
clean formatting/analysis and passing version-script fixtures. This includes
the later calibration, update-check, Drive metadata and tied-sort repairs.
Focused checks passed 12 update/editor tests, 40 Drive/controller tests,
67 sorting/library tests and 11 calibration/editor tests. All 22 Markdown
documents' local file links resolved; no signing stores or secret environment
files were tracked. This is not an exhaustive sign-off.


The third full cycle passed **574 tests**, with **20 opt-in renderers skipped**,
clean formatting/analysis and passing version-script fixtures. Final review of
the resume change caught a missed daily-plan refresh after an overnight pause.
Both complete/interrupted regression scenarios failed before repair and passed
after invalidating the plan on a changed local day. Same-day retention remains
covered. The final full verification after this repair also passed **574 tests**, with
**20 opt-in renderers skipped**, clean formatting/analysis and passing version
fixtures. Local release packaging passed; the APK reports `0.9.1+21` and uses
the established release certificate.
