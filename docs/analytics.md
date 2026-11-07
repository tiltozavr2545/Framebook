# Library analytics

Definitions for personal statistics, source comparison and derived people
credits. Screen interactions are in [product behavior](features.md);
recommendation scoring is a separate [algorithm](recommendations.md). Guided
movie-score review is specified in [pair calibration](pair-calibration.md).

## Scope and source comparison

All analysis is all-time and separated by title kind. Imported timestamps
are not viewing activity. Live ratings contribute; deleted ratings do not.
Genres for seasons/episodes come from the series. Genre names use cached
TMDB lists; missing names do not block other aggregates.

`divergence()` is personal score minus the source's value on a 1–10 scale.
Kinopoisk, IMDb and TMDB qualify; RT and Metacritic do not. Display uses a
sign and one decimal, with `±0` for equality. My ratings joins cached
Kinopoisk/IMDb values and sorts by absolute gap, higher personal score or
lower personal score. Entries without a value stay last, most recent first,
and display no data. The chosen source is a preference.

The hint below a season is the mean of its rated episodes. For a series,
use its rated seasons; if there are none, use rated episodes across seasons.
The contributing count accompanies the mean. This hint never supplies or
changes the independently saved parent score.

## Aggregates

`app/lib/data/library/stats.dart` and `insights.dart` implement pure
calculations over library inputs and return contributing works for drill-down.

| Metric | Definition or evidence requirement |
| --- | --- |
| Score summary | Count, mean, median, distribution in half points and population standard deviation |
| Score groups | High 8–10, middle 4.5–7.5, low 1–4 |
| Genre and decade summaries | Counts and means over contributing titles |
| Source gaps | Signed and absolute mean differences, with coverage counts |
| Preference agreement | Spearman correlation with average ranks for ties; at least three shared values and variance on both sides |
| Discoveries / disappointments | Personal-minus-source gaps at least +1 / at most −1 |
| Person and genre rankings | Mean/reliability rankings require three distinct works; frequency has no minimum |
| Mixed-feeling authors | At least one score of 8+ and one of 4 or less |
| Creative pairs | Director/actor combinations with at least three shared works; self-pairs excluded |
| Effective diversity | `exp(Shannon entropy)` over category contributions |

A person with several jobs counts once per title globally and once per
applicable role. People aggregates include only loaded credits matching the
stored title identity. A successful empty response counts as covered;
unloaded or displaced credits remain unknown.

## Credit enrichment

`PeopleIndex` loads compact cached credits before scheduling TMDB work.
It allows four concurrent requests, at most 80 titles and 45 seconds of
scheduling per pass, plus up to ten seconds for an in-flight request.
Network, authorization or quota failures stop further scheduling. Partial
results remain usable and the user can continue later.

Cache identity includes locale, natural work key and stored TMDB identity.
Numbered parts are verified before attribution. Series/seasons use aggregate
credits with every crew job; movies/episodes use ordinary credits including
guest stars. The derived namespace excludes incomplete older parsing results.
Credits remain evictable, outside permanent user data. Endpoint details and
cache fallback belong to [external sources](external-sources.md).

## State and scheduling

`insights_provider.dart` shares derived results between people browsing and
Stats, independently of favourites. Favourite changes and progress-only
updates do not rebuild aggregates. Counters subscribe separately from content.
Decade drill-down can use current local ratings while detailed insights load.

The synchronous path is limited to 80 titles, 1,000 credit entries and an
estimated 4,000 director/actor pair contributions. Larger inputs use a
serialized latest-input worker and retain the previous result. The estimate
may overcount duplicate credits; thresholds bound work rather than guarantee
phone frame times.

Large summaries filter inputs and precompute medians, score groups, source
agreement and discovery/disappointment lists in a worker. People ordering
uses a worker above 200 titles or 200 people. Retained results carry their
kind/selection so the UI does not relabel an older result as a new one.
Score profiles materialize during preparation, avoiding aggregate loops in
row rendering. Worker and layout verification is indexed in
[testing](testing.md).
