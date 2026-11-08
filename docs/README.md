# Documentation

Each topic has one primary document. Other documents link to that explanation
instead of repeating its rules, procedures or status. This index is the entry
point; the repository [README](../README.md) introduces the app.

## Product and technical reference

| Topic | Primary document |
| --- | --- |
| Screens, navigation, rating editor and visual conventions | [Product behavior](features.md) |
| Statistics, contributing works and people-credit enrichment | [Library analytics](analytics.md) |
| Taste signals, candidate retrieval, ranking and hidden suggestions | [Personal recommendations](recommendations.md) |
| Pair-comparison workflow and daily allowance | [Pair calibration](pair-calibration.md) |
| Runtime layers, state ownership, lifecycle and worker scheduling | [Client architecture](client-architecture.md) |
| Local tables, natural keys, snapshot identity and storage invariants | [Data model](data-model.md) |
| API endpoints, ID matching, parsing, cache lifetimes and request quotas | [External sources](external-sources.md) |
| Drive format, merging, deletion retention, restore and encrypted key sync | [Sync and backup](sync.md) |

## Guides and project records

| Topic | Primary document |
| --- | --- |
| Getting and entering personal API keys | [English guide](api-keys.md), [Russian translation](api-keys.ru.md) |
| SDK, local setup, dependencies, generated code and coding pitfalls | [Development](development.md) |
| Verification commands, regression conventions and device checks | [Testing](testing.md) |
| OAuth setup, signing, symbols, CI and release publication | [Operations](operations.md) |
| Android recovery and Samsung resume diagnostics | [Android troubleshooting](android-troubleshooting.md) |
| Current work and remaining delivery checks | [Implementation plan](implementation-plan.md) |
| Unscheduled ideas and unresolved product choices | [Future development](future-development.md) |
| Version history and explicitly unreleased changes | [Changelog](../CHANGELOG.md) |
| Findings, measurements and historical verification evidence | [Review index](reviews/README.md) |
| Original motivation and initial tradeoffs | [Project brief](project-brief.md) |
| Shared agent instructions | [AGENTS.md](../AGENTS.md) |

## Editing conventions

Use English for repository documentation and sentence case for headings.
Use present tense for current behavior, past tense for historical evidence,
and explicit pending status for unfinished work. Keep procedures as numbered
steps, comparisons as tables and explanations as short paragraphs.

Update the primary document when a decision changes. Keep implementation
details out of user guides unless they help the reader complete a task.
Exact declarations belong in source files; documentation explains their meaning,
boundaries and rationale. Avoid copying dependency lists or current version
numbers when a source reference will remain accurate.

The Russian API key guide is an intentional translation, not an extra technical
reference; keep it aligned with the English guide. The public site and privacy
policy in [gh-pages/](gh-pages/) serve a separate audience and must remain
self-contained. Review reports retain historical evidence; the changelog groups
changes by version, including explicitly unreleased entries. Neither defines
current behavior.

When adding a repair, update the topic reference for its resulting behavior,
record the user-facing change in the changelog and retain reproduction/test
results in the version's review report. Keep delivery status and outstanding
acceptance only in the implementation plan, and unscheduled ideas only in
future development. Reusable verification procedures belong to testing;
release-specific commands, samples and outcomes in reports are historical evidence.
