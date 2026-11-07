# Implementation plan

Current delivery status and remaining work. Released features belong in the
[changelog](../CHANGELOG.md), current rules in the
[technical references](README.md#product-and-technical-reference), and
verification evidence in the [review reports](reviews/README.md).

## Latest delivery

Version 0.9.3 implements the Settings layout repair, daily recommendation-source
rotation and guided pair calibration in movie statistics. Current behavior is
specified in [features](features.md), [recommendations](recommendations.md) and
[pair calibration](pair-calibration.md); the release history is in the
[changelog](../CHANGELOG.md#093--pair-calibration-and-fresher-recommendations-build-23).

Implementation, migration and compatibility checks are complete. Verification
results and their limits are recorded in
[delivery validation](reviews/delivery-validation.md#093--pair-calibration-and-daily-rotation).
The platform and independent-review work below remains separate.

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
