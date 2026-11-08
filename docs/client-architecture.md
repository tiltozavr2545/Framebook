# Client architecture

Runtime boundaries, ownership and scheduling in the Flutter app. Product
rules are in [features](features.md), persistent contracts in the
[data model](data-model.md), integrations in [external sources](external-sources.md),
and transport/merge behavior in [sync](sync.md).

## Components and layers

| Component | Responsibility |
| --- | --- |
| Flutter and `app/` | Startup, routing, theme, localization and device preferences |
| Riverpod | Reactive dependencies, scoped clients and prepared view state |
| go_router | Stateful tab branches and nested title/person routes |
| Drift / SQLite | Transactions and reactive library streams |
| Dio and source clients | Typed catalog/source values; no source DTOs in screens |
| `KeyStorage` | Secure key access, replaced with memory in tests |
| SharedPreferences | Device preferences, selected account and bounded local history |
| Google sign-in / Drive | Account authorization and transport behind testable interfaces |
| `file_picker` / `url_launcher` | System file flows and external pages |
| fl_chart | Statistics charts |

SDK and dependency constraints are maintained in [development](development.md).

```text
app/lib/
  app/                 startup, routes, theme, localization, preferences
  data/
    db/                tables, migrations and queries
    library/           mutations, views, analytics and snapshot identity
    recommendations/   taste profile, retrieval and ranking
    sources/           TMDB, PoiskKino and OMDb adapters
    sync/              codecs, pure merge, persistence and Drive transport
  features/            screens and feature controllers
  shared/              reusable UI, images, formatting and worker helpers
```

Source clients know only their own API and return domain values. The ratings
service chooses between sources; screens do not decide where an IMDb value
comes from. External parsing/failure rules belong to the source contract.
Sync merging is pure and independent of Drive and SQLite. Persistence applies
the result in a transaction. Screens observe Drift streams, so remote changes
update open library views without screen-specific invalidation.

## Startup and client ownership

`main()` renders `StartupApp` immediately. Initialization opens the database,
creates a device ID when necessary, reads preferences and keys, then injects
them through `ProviderScope` overrides. The first main frame therefore has
the saved locale, theme and onboarding state. Pending initialization follows
the system theme; failed attempts close the database before Retry.

Catalog/source providers depend on keys and content language. Search restarts
when its client changes; generation checks prevent pages from an old client
or query from entering the active result. Riverpod automatic retries are
disabled; explicit Retry controls handle source failures.

The shared HTTP client returns 4xx/5xx responses for source-level decoding;
transport failures remain exceptions. A service instance owns its in-memory
failure throttles and card-request statuses. Key changes recreate it, allowing
immediate validation/refresh without old responses replacing current status.

## Library writes and views

`Library` owns rating/watchlist mutations; screens do not write tables.
`PairCalibrationStore` coordinates confirmed score changes through `Library`
and records the comparison in the same database transaction. Rating persistence
includes lineage snapshots and watchlist removal in one transaction. Saving
unchanged score/note content creates no new user version. Snapshot identity
and timestamp rules are defined only in the data model.

Localized-title refresh selects live keys and ancestors at startup, language
changes, sync and resume. Successful unchanged identities reuse results for
24 hours per language/key generation; changed identities and failures retry.
It requires a key and foreground state. A late result cannot apply after
backgrounding or disposal.
Local read/write exceptions end only the optional pass; the next sync or resume
can retry without reporting an uncaught foreground-task exception.

Watchlist streams read only live entries, required snapshots, relevant season
rating keys and selection fences transactionally. They avoid full sync-state
reads. Rating-list ancestor queries batch at 400 keys to stay below SQLite
parameter limits. Poster score badges select from one shared live-rating map.

Filtering, ordering and day grouping run in a serialized worker above 200
ratings. Prepared results retain their selection settings while replacement
work runs. Filmography grouping/combined ordering similarly uses a worker
above 200 acting/crew credits and remains provider-cached for the route.
The controls select prepared lists. Analytics and recommendation thresholds
belong to their respective [analytics](analytics.md#state-and-scheduling) and
[recommendation](recommendations.md) specifications.

Pure preparation uses `ViewComputer`: production runs real isolates; widget
tests replace scheduling, with separate tests for actual isolate transfer.
Latest-input workers serialize computation, skip superseded queued inputs
and retain coherent previous results until a replacement is ready.
Large recommendation-credit messages share equal immutable leaves and prepare
in bounded batches before transfer; the preparation is cached per published
index snapshot. The exact scheduling contract belongs to
[recommendations](recommendations.md).

Pair selection runs locally in a serialized `ViewComputer` worker above 200
library rows. The screen keeps the current pair stable while its rating versions
remain valid, ignores obsolete worker results and cancels its day-boundary timer
when backgrounded or disposed. Workflow and selection priorities are specified
in [pair calibration](pair-calibration.md).

## Lifecycle and rendering

The shell retains non-rendering listeners for ongoing derived data and
foreground services. Nested cards can pause Discover widget subscriptions
without losing the live recommendation graph. These listeners do not rebuild
the shell for every enrichment update.

Optional background rating refresh keeps its loop alive after a local storage
exception. The active indicator resets and the next normal interval or resume
can retry; a failed pass does not start an immediate retry loop. A narrow
live-rating-key subscription wakes catch-up when titles are added or removed,
including additions during an active pass. It does not read notes or react
to cache updates. Missing-source and stale-cache phases share the same daily
counter; priorities and allowances belong to
[external sources](external-sources.md#request-budget).

Tab navigators exist in advance, but screens mount on first display. Hidden
branches stop tickers, focus and pointer input. Visited finite shelf sections,
card headers/editors/source panels/cast/related rows and expanded biographies
remain mounted for their page/route. Unbounded search, rating, season and
episode lists stay lazy. Horizontal shelves use fixed extents, stable keys
and separate PageStorage offsets. Discover defers feed-tree replacement until
vertical/horizontal scrolling and flings finish.

An opening card uses the shared known rating while its individual query is
pending; an explicit null from that query takes precedence. Optional loading
counters subscribe independently. Layout reserves placeholder reason lines,
source captions and poster borders to avoid geometry changes on completion.

`KeyboardRestore` observes lifecycle above the routes and restores the same
mounted primary editor after a frame only when its keyboard was previously
visible. Navigation pages and floating selection share one transition
controller. Glass indicators use gradients/highlights over an opaque surface,
without redundant backdrop filtering.

## Cache execution

`response_cache.dart` stores one atomic file per canonical TMDB request in
the OS cache directory. API credentials are excluded from cache identity.
Real lifetimes are used instead of extending freshness on every hit; this
replaces the earlier `dio_cache_interceptor` approach. Source-specific cache
lifetimes, stale fallback and quota rules are owned by
[external sources](external-sources.md#cache-and-lifetimes).

Catalog JSON and cache envelopes of at least 64 Ki characters parse/encode
in isolates. Derived credit lists decode above the same body threshold and
encode above 400 credits. Small inputs avoid isolate startup overhead.
Concurrent identical TMDB loads share one in-flight request by canonical
endpoint/parameters; `try/finally` clears success and failure paths.
Cache-age pruning uses asynchronous filesystem metadata reads.

## Images

`cached_network_image` uses a shared image cache; capacity, expiry and CDN
sizes belong to [external sources](external-sources.md). Image keys use size
plus relative path rather than a reissued full URL. Configuration supplies
the CDN base; a default is available before it loads.

Full-screen decoding preserves aspect ratio and up to fourfold zoom, capped
at 4,096 pixels per side. This bounds each decoded image, not the whole process
or download size. A 128-entry LRU retains successful poster colours, never
decoded images or failures. Sampling reads at most 4,096 pixels from the
cached w342 image. A saved-only card starts no tint request.

## Sync components

| Module under `data/sync/` | Responsibility |
| --- | --- |
| `sync_file.dart` | Strict, bounded rating-file codec |
| `merge.dart` | Pure deterministic merge and state comparison |
| `sync_store.dart` | Transactional reads, apply and explicit replacement |
| `sync_engine.dart` | One remote merge/upload pass and daily copies |
| `drive_remote.dart` | Drive implementation of `SyncRemote` |
| `google_account.dart` | Account initialization and authorization |
| `sync_controller.dart` | Scheduling, status, account actions, import/export and restore |
| `sync_actions.dart` | Coordinated rating/vault deletion and operation gating |
| `secrets_vault.dart` | Encrypted key codec, merge and secure pending state |
| `secrets_controller.dart` | Opt-in state, unlocking and applying restored keys/preferences |

`SyncStore` reuses the transaction's row snapshot instead of selecting every
merged row again. Full companions write nullable columns explicitly; otherwise
Drift upserts can retain an old note or tombstone. Orphan pruning selects keys
without decoding complete notes/snapshots. Google initialization shares
in-flight/successful attempts and permits retry after failure. Authorization,
format compatibility, client disposal and concurrency limits are specified in
[sync](sync.md).
