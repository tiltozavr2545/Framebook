# Implementation plan

Current delivery status and remaining work. Versioned changes belong in the
[changelog](../CHANGELOG.md), current rules in the
[technical references](README.md#product-and-technical-reference), and
verification evidence in the [review reports](reviews/README.md).

## Current work

Implementation and automated verification of the requested repairs in
0.9.5+25 are complete. Release assets and publication status belong to
[GitHub Releases](https://github.com/tiltozavr2545/Framebook/releases/tag/v0.9.5).
User-facing changes belong to the
[changelog](../CHANGELOG.md#095--stable-rating-dates-and-simpler-release-details-build-25);
confirmed findings, measurements and final verification belong to the
[0.9.5 review](reviews/0.9.5/README.md).

The user closed further code review on 2026-11-08. Documentation consolidation
is complete. Current behavior is maintained in the topic
references linked from the [documentation index](README.md), rather than
repeated here. Earlier milestone evidence, including the statistics redesign,
is retained in [delivery validation](reviews/delivery-validation.md).
Physical-device and independent-review acceptance below remains open.

## MVP stages

| Stage | Scope | Status |
| --- | --- | --- |
| 0 | Preparation, API checks and CI | Complete |
| 1 | Database, keys and settings | Complete |
| 2 | Search and title cards | Complete |
| 3 | Ratings, notes, watchlist and score comparison | Complete |
| 4 | External-score comparison and statistics | Complete |
| 5 | Drive sync and backups | Complete |
| 6 | Visual design and distribution | Complete |
| 6.5 | Required product follow-up | Complete; friends comparison postponed |
| 7 | Correctness review, measured optimization and independent re-review | Partially complete |

Post-MVP releases continue after these stages. Their history is maintained
only in the changelog; review findings and measurements are indexed separately.

## Remaining delivery work

- [x] Complete the initial correctness review and documented repair passes.
- [x] Implement the selected 0.8.4 optimization work and subsequent
  responsiveness repairs; retain their host measurements in review reports.
- [ ] Measure cold/warm startup, input latency, frame times, image memory and
  energy use on physical hardware. Host microbenchmarks do not establish
  device performance.
- [ ] Complete two-phone offline edits and synchronization in different
  orders, including conflict and recovery flows.
- [ ] Complete the remaining platform acceptance checks listed in
  [testing](testing.md#checks-that-still-need-a-device).
- [ ] Complete a fresh independent review of the resulting code without
  relying on earlier findings as its scope.

Run the applicable automated checks before handing over each change. Passing
them does not mark pending physical-device or independent-review work complete.
Unscheduled features and unresolved product choices remain in
[future development](future-development.md).
