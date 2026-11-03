# Framebook repository audit — 2026-11-02

Reviewed revision: `d0aec74`, version `0.7.2+11`, including the existing
uncommitted Google-resume fix. That fix predates this audit. No version bump,
commit, upload, account operation or installation was performed.

## Original audit result

The project is not ready for a correctness sign-off. The existing test suite
passes, but six additional local scenarios reproduce defects. The main gaps
are in orchestration between otherwise tested components: first vault enable,
identity changes during renumbering, destructive-operation boundaries, and
provider invalidation. Passing merge algebra tests does not establish these
end-to-end properties.

The findings below describe the starting revision. The subsequent repair pass
implements F01–F10; see the resolution record below. The original audit alone
did not change application source.

## Scope and method

All 264 Git-tracked files at audit start are accounted for in
[inventory.md](inventory.md), with the inspection method per file. There are
79 application source/template files, four generated Dart files, 35 Dart
test/support files, 34 JSON fixtures, 34 binary assets and 78 other files.
Binary assets and generated output receive format/build checks rather than
pretending to be handwritten implementation. Tests were inspected by scenario
and run; this does not claim every possible runtime interleaving was covered.
Ignored credentials, private local configuration, dependency sources and build
outputs are not repository source. Installed dependency implementation was
consulted where needed to verify package behavior.

iOS files were included in structural/configuration inspection; iOS is
explicitly postponed and was not built. No emulator was started. Live API
availability, current external registration forms, Google Cloud console state,
OEM process recreation and two-phone convergence were not verified. External
service accounts and user data were not accessed.

## Findings

### F01 — P1: first encrypted-sync enable drops phone-only API keys

Location: `app/lib/data/sync/secrets_controller.dart:192`,
`app/lib/data/sync/secrets_controller.dart:200`.

A phone with a manually configured OMDb key enables encrypted sync against a
Drive vault containing only TMDB. `_enable` calls `unlock` without staging the
phone's current keys. With no account-local vault snapshot, unlock returns the
remote snapshot; `_apply` calls `replaceRemote`, which removes the OMDb key
from both state and secure storage. The per-key merge in SecretsVault is not
the problem: its inputs never include that phone-only key.

Reproduced by `first enable discards a key that exists only on this phone`.
This contradicts the explicit preservation promise in `docs/sync.md` and both
API-key guides. Stage existing local keys with appropriate per-key versions
before the initial merge, preserving real removal tombstones and changed-vault
identity semantics. Add a controller-level regression, not only a vault test.

### F02 — P1: renumbering attaches an unrelated IMDb ID to the moved episode

Location: `app/lib/data/library/library.dart:437`,
`app/lib/data/library/work_snapshot.dart:119`,
`app/lib/data/sync/merge.dart:156`.

Rate E1 with own TMDB ID 101 / IMDb ID tt1111111 and E2 with own ID 102 /
IMDb ID tt2222222. Move E1 to E2 using the lineage supplied by the renumber
notice, which has no episode IMDb ID. The destination ends up with TMDB ID
101 and IMDb ID tt2222222. `adopt` updates the own ID, while null-to-absent
preserves the destination's unrelated external ID. Background/offline rating
refresh then queries the wrong episode by IMDb. The unconditional sticky-ID
merge can carry the mismatch between devices as well.

Reproduced by `a moved episode retains the previous target IMDb ID`.
External IDs must be tied to object identity. Transfer a known source ID or
clear an ID that belongs to the displaced identity, and invalidate affected
cached ratings. Audit Keep and snapshot refresh under the same rule. Preserve
merge convergence when changing snapshot-ID handling.

### F03 — P2: Drive deletion does not freeze new secret operations

Location: `app/lib/data/sync/secrets_controller.dart:258`,
`app/lib/data/sync/secrets_controller.dart:321`,
`app/lib/features/settings/sync_screen.dart:434`.

`prepareForDeletion` increments an epoch and drains current operations, but
returns with `enabled` true and without a deletion/suspension guard. A subsequent
key edit can start another upload; resume can start another load. The main
controller only drains its own rating-sync future. Secret controls also remain
available while rating-data deletion is busy. Thus the drain is not an exclusive
boundary for the deletion plus local-cache reset sequence.

Reproduced by `deletion preparation does not prevent a new key upload`:
after preparation returns, changing a key makes new remote calls. This proves
the missing exclusion; it does not by itself prove that an ordinary upload
recreates a deleted Drive file (an update to a missing file can fail).
Use a shared destructive-operation gate covering preparation, deletion and
reset, with explicit recovery on failure, and test resume/edits/overwrite while
deletion is blocked.

### F04 — P2: changing language leaves old search pages and mixes languages

Location: `app/lib/features/search/search_controller.dart:94`.

Search obtains TMDB with `ref.read`; it neither listens for a client/language
change nor invalidates the generation. An existing first page remains in the
old language, while loading the next page reads the new-language client. An
old in-flight request can also complete after changing language.

Reproduced by `changing source language mixes search pages` (RU then EN).
Restart the active query when content language changes and reject answers
from the old request generation. Preserve the intended query/tab state.

### F05 — P2: newly rated titles remain in the recommendations shelf

Location: `app/lib/features/search/shelves.dart:34`,
`app/lib/features/search/shelves.dart:47`.

The shelf watches only the three 8+ seed keys. Its set of all rated keys is
read once. Rating a recommendation below 8 changes the exclusion set but not
the seeds, so the shelf still recommends it. Deleting a non-seed rating has
the inverse stale-exclusion problem.

Reproduced by `rating a recommendation below 8 does not remove it`.
Keep recommendation fetching dependent on seeds, and filter the fetched list
reactively against all current rated keys. This fulfills the documented
"without what you rated" rule without unnecessary network requests.

### F06 — P2: a note accepted by the editor can fail at the storage boundary

Location: `app/lib/features/title/my_rating.dart:448`,
`app/lib/data/db/tables.dart:70`, `app/lib/data/sync/sync_file.dart:368`.

TextField maxLength counts grapheme clusters, SQLite length counts Unicode
code points, and sync validation uses runes. A note with 6,000 combining
`e + acute accent` clusters fits the editor limit but has 12,000 code points
and violates the database CHECK. Saving has no error presentation and the
editor is already dismissed. Similar cases occur with compound emoji.

Reproduced by `UI-valid grapheme count exceeds database note limit`.
Choose one documented unit and enforce it at input, Library and sync boundaries.
If changing the database constraint, use a real drift migration and previous-
schema test. Report save failure without silently losing the draft.

### F07 — P2: Android backup includes secure-storage files without a policy

Location: `app/android/app/src/main/AndroidManifest.xml:7`,
`app/lib/data/api_keys.dart:43`, `app/lib/main.dart:32`.

The application sets neither allowBackup nor backup/data-extraction rules.
The installed flutter_secure_storage 10.3.4 README explicitly warns that
Android automatic backup can restore encrypted preferences without the
matching Keystore key and recommends disabling backup or excluding them.
This includes cached vault key material, not only API keys.

The installed version also defaults resetOnError to true; therefore this is
not a claim that every restore crashes. Depending on the failing path it can
lose restored secrets or report a storage error. Choose and document a policy
for cloud backup and device transfer, exclude non-portable secure preferences,
and test restore on a physical Android device. Do not discard rating-backup
protection merely to silence a key-storage error.

### F08 — P2: startup failures have no usable recovery screen

Location: `app/lib/main.dart:23` through `app/lib/main.dart:42`.

Database, preferences, secure storage, package information and cache-directory
lookup all finish before runApp, without an error boundary. A thrown platform
or database exception prevents the first Flutter UI from appearing. The user
gets a splash/blank screen without retry or a way to export/recover data.
This is visible in control flow; no particular friend's black screen was
reproduced or attributed to it.

Keep successful startup behavior, but render a minimal failure/retry UI for
initialization errors, with no automatic destructive database/key reset.
Test failed secure reads and database opening through injectable initialization.

### F09 — P2: restoring a daily copy cannot repair a broken main Drive file

Location: `app/lib/data/sync/sync_controller.dart:376`,
`app/lib/data/sync/sync_controller.dart:455`,
`app/lib/data/sync/sync_engine.dart:338`.

The broken-file message suggests restoring a daily copy. Restore imports the
copy locally and calls ordinary sync, which encounters the same corrupt main
file and refuses to overwrite it again. Local data is restored, but remote
sync remains broken; the apparent repair does not unblock it. Deleting all
Drive data is available but also removes daily copies and the encrypted vault.

Provide an explicit, confirmed repair of the broken main file that preserves
other backups and secrets, or accurately explain that local restore alone
cannot repair Drive. Test the full controller flow with a corrupt main file
and a valid daily copy. Never use this path to overwrite a too-new format.

### F10 — P2: imports/downloads have no size boundary and decode on the UI isolate

Location: `app/lib/features/settings/sync_screen.dart:457`,
`app/lib/data/sync/drive_remote.dart:60`,
`app/lib/data/sync/sync_file.dart:198`.

FilePicker loads the entire file, Drive collects the complete stream, and
sync decoding expands gzip and parses JSON synchronously with no compressed
or expanded size limit. A mistakenly selected large file or a very large
compressed export can freeze rendering or exhaust memory before a friendly
"broken file" result. The vault's 1 MiB envelope check is not applied to the
rating format and itself occurs after download.

Bound network/file reads and decompressed output, give a clear size error,
and move substantial encoding/decoding work off the UI isolate. Establish a
supported library-size limit from realistic data before picking arbitrary
small caps. This is a control-flow/resource-bound finding, not an OOM experiment
on a user's phone.

## Documentation and presentation discrepancies

These are separate from the functional defects above:

- `docs/sync.md` and both API-key guides promise preservation of phone-only
  keys on enable; F01 directly contradicts that promise.
- `docs/client-architecture.md`, Offline, says an uncached card is unavailable;
  SavedCard implements the documented snapshot fallback in the same document's
  Title card section. Consolidate the two descriptions.
- `docs/client-architecture.md`, Lists, still says the watchlist contains only
  films and series, despite implemented grouped seasons.
- `docs/client-architecture.md`, Startup and keys, lists four key-check outcomes;
  KeyCheck has five, including an invalid source response.
- `docs/client-architecture.md`, Layers, places sync beside data; actual code is
  `lib/data/sync/`.
- `docs/operations.md` still describes Production OAuth as a future move;
  the implementation plan records it as completed. Live console state was not
  checked; reconcile against the actual account before changing operational facts.
- AGENTS and operations say Pages is copied on every main push; the workflow
  has a `docs/gh-pages/**` path filter.
- `syncBackupsHint` in both locales promises a copy for each of the last seven
  days. The engine retains seven copy files from days when it overwrites the
  existing main file; days without a write do not produce a copy. The restore
  message also omits the documented compact-deletion limitation on old backups.
- Privacy policy says automatic update checks happen at most once per 24 hours;
  failed checks can retry on every launch. Operations describes this exception,
  but the privacy wording does not.
- Some first-person UI text switches to formal plural in the secrets section;
  not a functional error, but localization voice is inconsistent.

No missing relative Markdown file links, JSON/XML/plist parse errors or missing
locale string keys were found by the structural checks.

## Maintainability findings

- `Library` combines snapshots, mutation/version rules, renumbering, watchlist
  selection fences, queries, sorting and provider declarations in 1,164 lines.
  Extract along responsibilities while retaining transactional coordination.
  File size alone is not a defect; the identity mismatch in F02 illustrates
  why cross-cutting rules need a single explicit owner.
- `SecretsController` in data imports `features/ratings/ratings_screen.dart`
  to get preference state. Move shared comparison-source state into app/data;
  data should not depend on a screen declaration.
- Deletion orchestration spans the Sync screen, two controllers, the vault and
  engine. No component owns the whole exclusive operation (F03). Move that
  coordination to a testable application service.
- Failure handling differs across layers: source errors get typed UI states,
  but platform/storage errors in startup and save handlers can escape entirely.
  Add boundaries around meaningful user operations instead of indiscriminate
  catch-and-ignore blocks.
- Full-state reads and repeated per-row queries appear in watchlist and sync
  paths. Record query counts and frame timing on realistic libraries before
  optimizing. This audit makes no measured CPU/battery improvement claim.
- DriveAccess creates authenticated HTTP clients without exposing a close
  operation; inspect ownership and ensure both retries and successful passes
  close clients. This is an ownership concern, not a measured leak claim.

## Original audit checks

- `make verify`: 353 passed, 18 screenshot-render scenarios skipped;
  formatting and analysis passed.
- `make codegen`: completed without tracked generated-code or schema changes.
- Explicit screenshot run: all 18 scenarios passed with real bundled fonts,
  producing both themes in `/private/tmp/framebook-audit-shots/`. Selected
  rendered screens were visually inspected; these are render tests, not golden
  image comparisons or OEM rendering tests.
- `make build-apk-check`: release APK compiled successfully, 66.6 MB.
  The SDK XML-version warning did not prevent compilation. The artifact was
  neither installed nor published.
- Six diagnostic cases originally confirmed F01–F06 by asserting the faulty
  behavior. These temporary cases were removed after desired-behavior
  regressions were added to the normal `app/test` suite.
- All tracked JSON/ARB, XML/workspace XML and plist files parsed; PNG signatures
  and chunk CRCs and font signatures were checked; relative documentation
  file links resolved; shell scripts/hooks passed `sh -n`.

## Resolution record

F01–F10 are included in the 0.7.3+12 release preparation. The original repair
pass did not bump the version; release preparation was authorized separately:

| Finding | Repair and regression coverage |
|---|---|
| F01 | Stage phone-only keys before initial vault merge; controller regression in `app/test/secrets_controller_test.dart`. |
| F02 | Keep part identifiers attached to their own TMDB identity, invalidate displaced cache entries, and merge complete part snapshots. Library and sync regressions cover Move, Keep and merge convergence. Format 4 rejects unsafe older writers; formats 1–3 remain readable, with derived part IDs discarded for rediscovery. A one-time local cleanup preserves user rating timestamps. |
| F03 | Suspend secret operations throughout deletion; `SyncActions` owns preparation, deletion and reset, including failure recovery. Controller tests exercise blocked edits, resume and overwrite. |
| F04 | Restart the active search on source-language changes and reject stale completions; search-controller regression. |
| F05 | Reactively filter fetched recommendations by all rated keys, without refetching unchanged seeds; shelf regression. |
| F06 | Enforce 10,000 Unicode code points consistently, retain full graphemes at input, and keep failed saves open with their draft; formatter and editor regressions. |
| F07 | Exclude both secure-storage preference files from Android cloud backup and device transfer; ordinary application data remains eligible. Physical restore remains unverified. |
| F08 | Render initialization progress and a retry boundary before loading application services; tests inject database and secure-storage failures. |
| F09 | Explicit confirmed repair archives corrupt mains, checks remote metadata and merges readable siblings while preserving backups and secrets; controller/engine tests include newer-format refusal. |
| F10 | Bound streamed input to 32 MiB and expanded content to 128 MiB; encode/decode on worker isolates. Tests cover limits and a 10,000-rating round trip. |

Shared rating preferences now live outside the screen; Library models and pure
sorting are separate modules. Authenticated HTTP clients have explicit owners
and are closed on success, failure and token retry. Documentation discrepancies
listed above have been reconciled, including backup retention and localization.

## Repair verification

- `make codegen` completed, with no local schema change.
- `make verify` passed: formatting, static analysis and 371 tests;
  18 opt-in screenshot scenarios were skipped in this normal run.
- Explicit screenshot run passed all 18 scenarios in both themes, writing
  `/private/tmp/framebook-fixes-shots/`; the updated editor was visually checked.
- `make build-apk-check` passed: release compilation, 66.7 MB APK, using
  the debug-signing fallback for compilation only; not for distribution.
- `git diff --check` passed; 58 tracked/new JSON, ARB, XML and plist files
  parsed successfully.

## Remaining validation

Physical Android backup/transfer, process recreation, and convergence between
two phones using real Google transport remain manual checks. The Samsung S23 /
Android 14 / One UI 6.0 black-screen report initially appeared resolved after
update. On 2026-11-03 the user confirmed it still occurs on 0.7.3 after about
five minutes in the background, while the Nothing Phone is unaffected. The
incident was reopened and a native Samsung API 34 surface-relayout workaround
added in 0.7.4. After receiving the release-signed APK, the user confirmed it
works on 2026-11-03 and authorized release; see `docs/operations.md`.
The original repair pass did not establish its cause.
No emulator, installation, account change or publication was performed.

Performance-sensitive queries still require query counts and frame timings on
realistic libraries before optimization. The independent second review in
Stage 7 remains pending. Passing automated checks is not proof of every
possible lifecycle or external-service interleaving.
