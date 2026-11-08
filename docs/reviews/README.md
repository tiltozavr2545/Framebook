# Reviews and validation records

Historical findings, measurements and verification evidence. Each report
describes the code and checks at that time; it does not define current
behavior or authorize repeating a past release action. Current work is tracked
in the [implementation plan](../implementation-plan.md).

| Record | Scope |
| --- | --- |
| [Delivery validation](delivery-validation.md) | Milestone checks, calibration/rotation and statistics redesign |
| [2026-11-02 audit](2026-11-02/README.md) | Repository inventory, correctness findings, resolutions and verification |
| [2026-11-05 review](2026-11-05/README.md) | Cache/source races, import recovery and initial optimization measurements |
| [0.8.4 optimization](../optimization.md) | Selected changes, host measurements, rejected options and packaging results |
| [2026-11-06 responsiveness review](2026-11-06/README.md) | Favourite-people, recommendation and statistics responsiveness |
| [0.9.0 review](0.9.0/README.md) | Sync application cost, credits, clock corrections and layouts |
| [0.9.1 review](0.9.1/README.md) | Resume, rating-editor races, source validation and narrow layouts |
| [0.9.2 review](0.9.2/README.md) | Shelf stability, worker preparation and retained view state |
| [0.9.4 review](0.9.4/README.md) | Storage/sync correctness, title identity, recovery and measured worker responsiveness |

The [Samsung investigation](../android-troubleshooting.md#samsung-android-14-resume)
keeps its affected-device evidence beside the diagnostic procedure.
Reusable commands and test conventions belong to [testing](../testing.md),
not to individual release reports.
