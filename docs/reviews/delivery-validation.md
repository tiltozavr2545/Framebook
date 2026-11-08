# Delivery validation records

Historical evidence moved from the implementation plan during documentation
consolidation. These are recorded results, not checks rerun for the
documentation rewrite. Dedicated audits and measured optimization reports are
listed in the [review index](README.md) rather than repeated here.

## Bottom navigation visibility repair — 2026-11-07

`make verify` passed: 628 tests passed and 22 were skipped; formatting and
static analysis passed. A widget regression covers both navigation styles on
movie, series, season, episode and person cards and restoration after Back.
Existing card workflows and full cast layout checks follow the new visibility
rule. Full-screen image routes open on the root navigator.

No APK build or physical-device check was performed for this repair.

## Initial Android delivery

The preparation-stage universal compile-check APK was 46.6 MB. Release
signing was checked locally with apksigner and through the release workflow.
On 2026-10-23, version 0.1.0 was installed on a phone: startup, onboarding,
system theme and system language were checked.

An invalid-package report for 0.3.0 was resolved by downloading the APK again;
the recorded cause was a damaged download. Release certificate verification
was subsequently included in the workflow.

The Stage 5 record confirms explicit Google sign-in and the first Drive upload
on a physical phone with a release-signed build. The two-phone offline merge
scenario remained untested. Production OAuth configuration is recorded in
[operations](../operations.md#testing-or-production).

Early visual checks used screenshot renders with real fonts and signed phone
previews. They prompted changes to whole/half-score sizing and comparison-panel
placement; rendered PNGs alone were not device validation.

## People search and title-card expansion

| Milestone | Recorded automated result | Device/build evidence |
| --- | --- | --- |
| 0.8.0 | `make verify`: 376 passed, 18 skipped | User confirmed the signed build on Samsung Galaxy S23 on 2026-11-03 |
| 0.8.1 | Codegen, verify and version checks; 389 passed, 18 skipped | Signed update on Nothing Phone 3a; quiet startup and image layout confirmed by the user |
| 2026-11-04 test-suite audit | Verify with coverage: 421 passed, 18 skipped | Signed update, cold start, Discover, saved ratings, Stats and short resume checked on Nothing Phone 3a |
| 0.8.2 | Codegen, verify and version checks; 436 passed, 18 skipped | Signed 66.9 MB APK; light/dark card renders inspected; 0.8.2+16 installed and user-confirmed on 2026-11-04 |

The 0.8.1 startup check observed Framebook as the focused activity after two
cold launches; this was not evidence of a completed live Drive sync. Delayed
image tests covered poster, person-photo, episode-still and cached-only layout.
The test-suite audit did not validate destructive Drive operations, system
file-picker flows, two-device sync or long Samsung background pauses.

The 0.8.2 regressions included facts, related titles, score colours,
calibration groups and keyboard restoration. Phone updates preserved existing
app data; no uninstall was used.

## Insights and recommendation previews

The initial 0.8.5 insights/favourites scope passed codegen and full verification:
500 tests passed, 18 opt-in renderers skipped. Coverage included v1 data
preservation, favourite merge laws, codecs, bounded credit loading, offline
disposal, distinct-work metrics, tied-rank correlation, day headings, history
visibility, large text and Stats navigation. A dark Stats render was inspected.
The signed 63.1 MB universal preview installed over 0.8.4 on a physical phone;
launch was checked, but device performance was not timed.

The hybrid recommendation preview passed codegen and verify with the expanded
reporter: 522 tests passed, 20 renderers skipped. Both recommendation renders
were inspected in light/dark themes. Tests covered reactive exclusions,
hidden preference persistence, Undo/restore and returning from nested cards
while data changed. An initial credit-index event was checked not to schedule
a duplicate network batch. The signed 63.3 MB preview retained version
0.8.5+19, installed over the previous preview, and was confirmed by the user.
Its matching symbols were preserved separately.

Later responsiveness repairs and their measurements belong to the
[2026-11-06 report](2026-11-06/README.md).

## Settings and daily rotation development baseline

The pre-existing working-tree record reported `make verify`: 601 tests passed,
20 opt-in tests skipped, formatting and analysis clean. It predates the
pair-calibration completion and does not validate those later changes.

Settings interaction/alignment checks used 320 dp, English/Russian, normal
and doubled text; light/dark renders were inspected. Rotation tests covered
daily stability, source coverage, request budgets, separate page caches and
offline daily-refresh recovery. These results do not establish a measured
improvement in recommendation relevance or device frame times.

## 0.9.3 — Pair calibration and daily rotation

The completed implementation passed `make verify`: 627 tests passed and
22 opt-in renderers were skipped; formatting and static analysis were clean.
`make codegen` completed for schema 3 and sync format 6. Settings renders and
pair calibration before/after an answer were inspected in light and dark themes.
The release candidate is `0.9.3+23`; release hooks repeat verification and compile
the universal APK before upload, and the publication workflow verifies signing.

Regressions cover deterministic pair selection and conflicting two-step chains,
equality without a false strict preference, confirmed corrections at score
boundaries, stale/deleted ratings, concurrent note edits, duplicate answers and
quota races. The fake-Drive scenario preserves the shared five-answer allowance;
comparison-only changes trigger autosync. History round-trips through exports
and remains present after explicit replacement with an older file. Migration
checks preserve v2 data in v3; codec checks reject malformed/duplicate v6 events
and keep legacy reading. Widget checks exercise hidden scores, equality, skips,
confirmation and next-day access in English/Russian at 320 dp with doubled text.

Daily recommendation and Settings regressions retain the baseline coverage
above. Documentation was consolidated into primary topic references and checked
for local links and anchors before release.

These are host tests and rendered UI checks, not physical-device acceptance,
measured recommendation relevance or an independent code review. Remaining
platform work stays in the [implementation plan](../implementation-plan.md#remaining-delivery-work).
Distribution: [v0.9.3](https://github.com/tiltozavr2545/Framebook/releases/tag/v0.9.3).

## Statistics redesign — 2026-11-08

The selected overview-and-details layout replaced the long statistics feed.
It keeps the existing theme, score colours and poster components. The root
shows count, mean, highly rated titles and eligible favourite genres. Separate
routes hold score distribution, genres/decades, actors/directors and Kinopoisk/
IMDb comparison. Calibration uses a nested route too. Secondary pages hide
both tab-navigation styles and retain their originating screen beneath cards.

`make codegen` completed. The final
`make verify TEST_ARGS='--concurrency=2 --reporter expanded'` passed with
748 tests and 22 opt-in renderers skipped; formatting, static analysis and
version-script fixtures were clean. Focused checks covered deterministic
genre/high-score ordering, the role-specific three-title minimum, real worker
transfer, lazy expansion across 1,000 people and decade drill-down before
people enrichment completes. Twelve navigation journeys used 320 dp, both
languages and themes, and text scales of 1, 1.3 and 2. They covered source
selection, comparison values, contributing works, title/person links, Back
and measured title bounds. Full-app scenarios covered both navigation styles,
including the calibration route, and the high-score shelf's work list.

Two opt-in screenshot scenarios produced fourteen renders with bundled fonts:
the overview and four detail pages in both themes, plus enlarged overview and
comparison pages. Representative renders were inspected; the full app retained
its existing 1.3 text-scale cap. Inspection caught excessive poster-shelf
spacing and a clipped intermediate-scale comparison heading; both were repaired.
The [tracked overview image](../screenshots/stats-dark.png) was refreshed.

The project version/build, schema and sync format did not change. These are host
functional checks and visual renders; no physical-device acceptance or
performance measurement is claimed. Remaining platform work stays in the
[implementation plan](../implementation-plan.md#remaining-delivery-work).

The signed universal release preview subsequently built successfully (64.3 MB)
and installed over the existing app with `adb install -r`, without clearing
app data. Android confirmed version 0.9.4, build 24, and a successful cold
activity launch. The user chose to inspect the UI themselves; this installation
check does not mark visual or broader physical-device acceptance complete.

### Entry actions and kind selection follow-up

Compare films moved directly below the count/mean summary and became a
full-width violet primary button with a short explanation beneath it. The
four kind chips were replaced by an inset sliding selector sharing the same
rendering component as Discover's two-mode field. Compact labels stay on one
line and scale down within equal segments instead of splitting a final letter
onto another line.

The follow-up passed `make verify` with 753 tests and 22 skipped renderers;
formatting, static analysis and script fixtures were clean. Four new gesture
checks covered taps, pointer cancellation, RTL and reduced motion at large
text size. The full-app drag regression kept the Stats root tab active while
changing the selected kind. Existing Discover drag/query behavior and the
twelve statistics navigation journeys also passed. Both theme render sets
were regenerated and the overview images were refreshed. App version/build
and schema/sync formats stayed unchanged; the UI follow-up introduced no
user-data migrations.

The refreshed signed universal APK built successfully (64.4 MB) and was
installed over the previous preview with `adb install -r`. Visual acceptance
on the physical device remains the user's manual check.

### Separate calibration panel follow-up

The calibration entry now groups its own heading, explanation and primary
button inside a separate panel below the summary. Its violet gradient and
border use the same shared decoration as person headers. The explanation
sits above the button and the summary has additional spacing before the panel.

`make codegen` completed and `make verify` passed with 753 tests and 22 skipped
renderers; formatting, analysis and version-script fixtures were clean.
Both screenshot scenarios passed and produced fourteen renders. The overview
was inspected in both themes and with enlarged text, and the tracked overview
images were refreshed. App version/build and data formats stayed unchanged.

The signed universal APK built successfully (64.4 MB), installed with
`adb install -r` and completed a cold activity launch. Physical-device visual
acceptance remains the user's manual check.

### Overview scrolling and Cyrillic follow-up

The overview used short lazy lists for unequal summary and navigation rows.
Scroll regressions reproduced changes in the estimated content extent during
scrolling in both languages, including a 54 dp correction with enlarged text.
The bounded sections now lay out their complete contents, keeping the scroll
range constant. The four locale/scale cases passed after failing before the fix.

Bundled Sofia Sans uses Bulgarian Cyrillic by default. The text theme now
selects Russian glyph forms independently of the interface language, including
for saved titles and notes in English mode. A real-font raster comparison
reproduced the difference before the fix and passed afterward across both
families and five text styles.

`make verify` passed with 758 tests and 22 skipped renderers; formatting,
analysis and version-script fixtures were clean. Both screenshot scenarios
passed and generated sixteen images, including the English overview in both
themes. Representative renders were inspected and tracked overview images
were refreshed. These host checks establish stable layout geometry and glyph
selection; they do not measure scrolling frame times on Android.

The signed universal preview built successfully (64.4 MB) and installed over
the existing app with `adb install -r`, preserving app data. Android confirmed
a successful cold activity launch. Version/build remained 0.9.4+24; the user
will assess scrolling smoothness and typography on the physical device.

## Rating dates and release details — 0.9.5

Implemented on 2026-11-08. Version 0.9.5+25 preserves `scored_at` for ordinary
score edits and direct score corrections across films, series, seasons and episodes. Edits advance
the sync version; deleting and rating again sets a new diary date. Existing
dates remain unchanged, without a schema migration or sync-format change.

Unknown or invalid release dates appear in each card's header date field,
including saved offline cards, in both interface languages. The separate
pending-release label and explanation below rating controls were removed.
Rating and recommendation eligibility rules were retained.

`make codegen`, `make verify` and `make verify-version` passed. The final full
suite passed 773 tests with 22 opt-in renderers skipped; formatting, static
analysis and version-script fixtures were clean. Regression coverage checked
persisted dates, complete date ordering, re-rating with the same score after deletion,
lagging clocks, unchanged saves and two-device sync for all four title kinds.
Full-app checks exercise header placement in both locales, offline cards,
future-film restrictions and undated series. No physical-device check or
installation is claimed for this change.
