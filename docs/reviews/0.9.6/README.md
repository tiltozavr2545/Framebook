# 0.9.6 statistics presentation

The statistics page restores the presentation from before library insights were
introduced: a large personal average, half-point distribution and inline source
comparison blocks. The current kind switcher, prepared-view worker pipeline,
retained selection and local-library error recovery remain in use.

The overview places high-rated posters immediately below the chart, decades
below the posters and all rated genres below the decades, including one-work genres. It omits people
and detail-navigation sections.
Their calculation code and existing detail/calibration routes remain tracked.

## Validation

- Narrow layouts pass all twelve language/theme/text-scale combinations in
  `stats_navigation_test.dart`; the average scales down within its available
  width. The initial restored fixed-width figure overflowed at larger scales
  and was corrected before the device build.
- `make verify-version` passes for 0.9.5+25 to 0.9.6+26.
- The signed release APK builds successfully.
- A physical Nothing Phone 3a accepts the APK through an in-place update.
  Android reports versionName 0.9.6 and versionCode 26. The statistics page
  opens with existing ratings, the retained switcher, distribution and both
  source-comparison blocks visible.
- Final `make verify` passes: 821 tests passed, 22 skipped, clean analysis,
  formatting and version-script checks.
- All 83 focused application/statistics tests pass with decades and all genres.
- The final signed build, including decades above genres, is installed on the
  same phone without clearing application data.

The physical-device check covers the restored statistics page and update
installation; it does not establish complete sync or platform acceptance.
