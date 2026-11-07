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
