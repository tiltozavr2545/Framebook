# Project brief

The motivation and tradeoffs recorded when Framebook began on 2026-10-19.
This is historical context. Current behavior is described in
[product behavior](features.md), delivered changes in the
[changelog](../CHANGELOG.md), and unscheduled ideas in
[future development](future-development.md).

## Motivation

Personal film ratings tend to be scattered across services and notes. Each
service emphasizes its own public score, making it hard to compare a person's
scale with several public sources over time.

Framebook was conceived as a diary owned by its user, with external scores
beside personal ratings. Divergence from public scores and comparison with
earlier personal ratings were central to the idea: they help reveal taste
differences and changes in how someone uses their scoring scale.

The initial audience was the author and a few friends. That made direct APK
distribution practical, while preserving years of personal ratings remained
a core reliability requirement.

## Initial tradeoffs

| Decision | Rationale |
| --- | --- |
| Flutter and Android first | Familiar tools and direct APK distribution |
| User-owned local data and Drive storage | Avoid operating a backend or requiring a separate app account |
| TMDB as the catalog anchor | Search, numbered TV parts, images and external IDs from one source |
| Optional PoiskKino and OMDb integrations | Bring several public ratings together without making each source essential |
| User-supplied API keys | A key embedded in a client can be extracted and shares its quota across installations |
| Independent ratings for whole titles and parts | A series can be strong overall and weak in particular seasons |
| Small snapshots plus evictable caches | Keep the personal library usable offline without storing a catalog |

## Risks identified at the start

External providers could change their endpoints, quotas or availability.
Client isolation and optional rating sources were chosen to contain that risk;
current integration details belong in [external sources](external-sources.md).

Small daily quotas meant that large libraries would acquire comparison scores
gradually. The design therefore required cached values and a request budget.
Drive integration required careful merging and recoverable backups rather
than treating a shared file as a server database.

TMDB reachability from Russian IPs was considered during preparation and
closed on 2026-10-20 because the intended usage did not require it. A fallback
catalog was not included in the scope.
