# Sync and backup

How user data moves between devices and how not to lose it. There is no
server — the user's own Google Drive plays the shared storage. What exactly
is synced is in [data-model.md](data-model.md).

**Status: implemented in Stage 5 (0.5.0)**, `app/lib/data/sync/`; where
things live is in [client-architecture.md](client-architecture.md), "Sync
and backup". When this file and the code disagree, the code is right.

---

## The overall scheme

- Sign-in is Google Sign-In with the single scope
  `https://www.googleapis.com/auth/drive.appdata`. The app sees **only its own
  hidden folder** (`appDataFolder`) — neither the rest of the user's Drive,
  nor its own files in the Drive UI. The scope is non-sensitive, which makes
  setting up the OAuth app simpler (see [operations.md](operations.md)).
- The folder holds one state file, `framebook-sync.json.gz`, and up to seven
  daily copies, `framebook-backup-YYYY-MM-DD.json.gz`.
- Every device keeps the **full** state locally and merges it with the file
  when syncing. There is no operation log and no "main" device.
- Without signing in, the app works fully, just on one device.

---

## File format

JSON, gzipped. Rows are the same columns as in the database, in
`snake_case`; time is UTC ms; a score is `score_half`.

```json
{
  "format_version": 3,
  "purged_before": 0,
  "rating_deletions": [],
  "watchlist_deletions": [],
  "watchlist_fences": [],
  "written_at": 1760870400000,
  "written_by": "6f1c…-device-uuid",
  "app_version": "0.7.0+9",
  "works": [
    {"work_key": "tmdb:tv:1399", "kind": "tv", "parent_key": null, "tmdb_id": 1399,
     "imdb_id": "tt0944947", "kp_id": 464963, "title": "Игра престолов",
     "original_title": "Game of Thrones", "release_date": "2011-04-17", "year": 2011,
     "poster_path": "/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg", "genre_ids": [10765, 18],
     "snapshot_updated_at": 1760870000000}
  ],
  "ratings": [
    {"work_key": "tmdb:tv:1399", "score_half": 17, "note": "The first four seasons are a 9",
     "created_at": 1760000000000, "scored_at": 1760000000000,
     "updated_at": 1760000000000, "updated_by": "6f1c…", "deleted_at": null}
  ],
  "watchlist": []
}
```

(`title` is in the locale the snapshot was taken in — here, Russian.)

Format rules:

- `format_version` goes up on **any** change of the set of fields, even when
  an optional one is added. An old client doesn't know the new field, and
  when it rewrote the file the field would silently disappear for everyone.
  The alternative — keeping unknown fields as a raw tail and writing them
  back — is more expensive, and is only needed when versions coexist for a
  long time. One person with two phones doesn't have that.
- A client that sees a `format_version` higher than it supports doesn't sync
  and shows "update the app". It has no right to overwrite the file with its
  own view.
- A new client reads all earlier format versions (migration on read) — this
  is also needed for importing old exports.
- The file gets retained `ratings` and `watchlist` rows, their compact deletion
  records, and the `works` rows the retained rows refer to, with their ancestors.
- Translated `title` text is device-local at an equal snapshot version:
  changing language neither advances `snapshot_updated_at` nor makes one
  device upload its language over another's.
- Version 2 adds `purged_before` and compact deletion records; version 1
  reads with a zero watermark and no compact records. Version 3 adds
  `watchlist_fences`; versions 1 and 2 are read with a series-selection
  register derived from each live whole-series entry. Older clients must
  update before syncing a newer file.
- API keys, settings and the rating cache never go into the rating sync
  file. Optional encrypted key sync uses a separate file (see below).

---

## Merging

Every `ratings` and `watchlist` row is an LWW register (last write wins) keyed
by `work_key`. The version with the larger `(updated_at, updated_by)` wins:
time first, and on a tie the lexicographically larger `device_id`. A
tombstone is an ordinary version of the row and wins or loses by the same
rules. At an identical timestamp and device id, deletion wins over a live
row; remaining ties use a SHA-256 digest of canonical row JSON. A compact
deletion retains that digest as `tie_break`, so compaction preserves its
ordering against full rows. `works` rows merge by `snapshot_updated_at`,
then canonical snapshot JSON. `imdb_id` and `kp_id` are sticky independent
fields: a side that found an id cannot lose it to an otherwise winning
snapshot where that id is null.

This merge is **commutative, associative and idempotent**: whatever order and
however many times the devices synced, the states converge. This property is
the main thing the rest of the algorithm rests on, and it is covered by tests
on random sequences of edits (property-based).

### Series and season watchlist choices

Each series has two permanent LWW selection registers: the latest explicit
whole-series selection and latest season selection. A visible series or
season entry must be newer than the opposite register. Selecting a whole
series hides older season entries; selecting a season hides an older series
entry. Multiple seasons newer than the last series selection remain visible.
Versions use `(updated_at, updated_by)`, with a local edit always newer than
both known group registers, even if the clock lags.

The ordinary watchlist rows remain independent LWW registers: a row hidden by
an opposite selection is retained rather than fabricated into a new version.
This preserves associative merging and prevents stale devices from bringing
back an older choice after the winning entry is later removed. An explicit
replacement import restores the file's visible selections as new edits.
An active season rating also hides its list entry, and editing or deleting a
season rating records a per-key watchlist tombstone so older offline list
entries do not return when the rating is removed. The group registers live
in the existing `sync_state` key-value table and travel in format 3 exports.

### One pass of the algorithm

1. Find the file: `files.list` in `spaces=appDataFolder` by name. If there
   are several files with that name (two devices created the first file at
   the same time), merge them all, keep the oldest, delete the rest.
2. Download the content (`alt=media`) and remember `modifiedTime`.
3. Check `format_version`.
4. Merge the remote state with the local one in **one transaction**, including
   compact deletion registers. Before applying a compact deletion over a live
   local edit made since the last successful sync, pause for Keep / Discard.
   Keep writes a new version above the deletion; Discard applies it. The
   consent is tied to the exact conflict versions shown. If those change
   while the dialog is open or during a retry, ask again before applying.
5. If the merged state has rows where the local version won (that is, the
   remote differs from the merged), or old full tombstones need compaction,
   compact and upload the merged state. Before uploading, re-read the file's
   metadata for every state file: if `modifiedTime` changed after step 2, go
   back to step 2 (at most three attempts). Check each duplicate again before
   deleting it.
6. Write the pass start time as `last_sync_at` and `modifiedTime` to
   `sync_state` after success. An edit during upload remains unsynced for the
   next pass; a paused or failed pass does not advance this acknowledgement.

Drive API v3 has no conditional write (If-Match) for content upload, so a
race window remains between metadata checks and writes or duplicate deletion.
Another device's update can be overwritten or its duplicate removed after
the last check. Its local copy can restore the change on a later sync, but
the shared file may lack it until then. If that device loses its local data
before another successful sync, the change may be lost. Every device keeps
the full state to make recovery possible; the metadata check is not an atomic
write or deletion.

### When to sync

- on app launch and on returning to it, if more than 5 minutes have passed
  since the last sync;
- 30 seconds after the last change (debounce);
- changes during a pass schedule another pass after the debounce;
- with the "Sync" button in settings.

Automatic startup first restores the saved Google session silently. If that
cannot be done while offline, the account remains configured and retry waits
for a later resume instead of showing "sign in again". Every Drive request has
a 30-second timeout.

With no network it is quietly put off until the next occasion. In the MVP
there is no sync in the background (while the app is closed).

### Device clocks

`updated_at` comes from the device's clock. If one device's clock is an hour
behind, its edit loses to an earlier edit from the other device for that
hour. For one person with two phones this almost never happens. The guard
against the worst case is monotonicity within a row: the new
`updated_at = max(now, previous updated_at + 1)`, so an edit on a device with
a lagging clock at least doesn't lose to its own previous version.

### Tombstones

Full tombstone rows are retained for **180 days**. Before uploading, cleanup
advances `purged_before` to `max(previous, now - 180 days)` and compacts
full tombstones whose `updated_at` is strictly below that boundary. A row
exactly on the boundary stays. Incoming watermarks are clamped to at most
this device's `now - 90 days` to limit the effect of a clock far ahead.

Compaction removes the score, note and unneeded snapshots, but keeps a
small permanent deletion register for each table/key and winning deletion
version (`work_key`, `updated_at`, `updated_by`, `tie_break`), in
`rating_deletions` and `watchlist_deletions` arrays. These records travel with sync files, exports and daily backups.
A compact deletion participates in the same deterministic LWW merge as a
full tombstone; a newer explicit user edit can restore the title. Compact
records do not need a `works` row or its ancestors.

The watermark controls compaction age only: absence of a key does **not**
prove it was deleted. Inferring deletion from absence and a global date
made the three-device merge depend on grouping, so that prototype was
replaced with exact per-key deletion records. Permanent compact records
are the bounded-cleanup exception to retaining full synced rows forever;
the number of keys in these records can still grow over time.

Cleanup prunes snapshots outside the lineage of every retained rating or
watchlist row, including full tombstones. A series or season needed by a
remaining episode is retained. Failed uploads must leave deletion knowledge
locally so a retry cannot resurrect an older row.

---

## First sign-in and sign-out

- **First sign-in on a device with local data, when Drive already has a
  file**, is an ordinary merge, not a replacement. Before it there is a
  dialog with counters: "120 ratings on the device, 340 in Drive, 395 after
  merging". A local watchlist also triggers this confirmation. The account
  is remembered for automatic sync only after the user confirms.
- **Signing out of Google** — the local data stays, the file in Drive stays.
- **"Delete data from Google Drive"** deletes the file and the copies. Other
  devices still signed in will create the file again from their state on
  their next sync; the confirmation dialog says so.

---

## Backup

Sync is not a backup: deleting a rating by mistake spreads to all devices as
faithfully as a correct change. So, separately:

- **Daily copies in Drive.** The first sync of the day, before uploading,
  copies the current file to `framebook-backup-YYYY-MM-DD.json.gz`. The last
  7 are kept, older ones deleted. Restoring is from a list in settings.
- **Export to a file** — the same format, through the system "Share" or "Save
  to…" dialog. Works without a Google sign-in.
- **Import from a file** — **merge** by the same rules by default. There is a
  "Replace everything" option, with a confirmation: everything local that
  isn't in the file gets a tombstone with a new `updated_at`, so the
  replacement spreads to the other devices instead of being rolled back by
  them.
- **Restoring from a daily copy** — the same as an import with replacement.
- Compact deletion records remain authoritative when reading an older file:
  replacement must filter versions already beaten by a known deletion before
  giving retained content a new timestamp. An old export cannot silently
  revive a purged deletion. A recent full tombstone can still be undone by
  explicitly restoring a backup; compaction makes the deletion permanent for
  old backups while the title remains deleted. If the title has already
  been rated or listed again, an explicit restore can recover its earlier
  score or content. Ordinary merge uses the same deletion registers.

---

## Errors

| Situation | Behaviour |
|---|---|
| no network | quietly put off |
| 401 / token revoked | a note in settings, "sign in again", no modal dialogs |
| Drive quota exceeded | a message in settings; local work doesn't suffer |
| the file can't be read (broken JSON, gzip) | don't overwrite; a message and an offer to restore from a daily copy |
| `format_version` is newer | "update the app", sync is off until updated |

The last error is kept in `sync_state.last_sync_error` and is visible in
settings along with the time of the last successful sync.


## Optional encrypted key sync

This is separate from the rating sync file and disabled by default. Enable
it on the Sync screen to share API keys and `divergence_source` between
signed-in devices. Theme and language stay local. The encrypted file is not
included in rating exports or daily rating backups. Deleting app data from
Drive deletes it too.

The user chooses a password of at least eight characters. A password-derived
key encrypts the entire payload with AES-256-GCM; every write has a fresh
nonce and authentication tag. Argon2id uses 19 MiB, two iterations, parallelism one and a 32-byte output;
it runs in an isolate so derivation does not block rendering. Its random 16-byte salt and fixed algorithm parameters accompany
the ciphertext and are authenticated. The derived key is cached only in OS
secure storage for the account and encryption identity; the password is
never stored. Keys are never put in SQLite, logs or ordinary preferences.
The format and parameter checks reject unsupported or malformed files
before overwriting anything.

A new device can restore from Google Drive during onboarding before it has
a TMDB key. It signs in and asks for the password, then restores keys and
the comparison source. The derived key is remembered on that device. A file
with a changed password or salt requires unlocking again; it is not silently
overwritten with this device's old key.

Disabling key sync waits for already started operations before clearing the
local cached key and snapshot. The encrypted file already on Drive remains
until the user deletes the app's Drive data.

Edits and key removals automatically update per-source LWW registers inside
the encrypted file. Each API key has its own monotonic UTC timestamp and
device id; removal is an explicit versioned tombstone. The comparison source
has a separate register. Enabling or unlocking therefore merges keys that
exist only on this phone with keys from Drive instead of replacing either
side wholesale. The authenticated envelope is version 2; the app reads
version 1 and upgrades it on the next successful write, while older clients
reject version 2 rather than discarding its per-key metadata.

A failed upload keeps pending changes for retry. Applying a remote snapshot
must not turn it into a new local edit or create an upload loop. The same
Drive metadata-check/write race described above also applies here: a device
retains its newer registers in secure storage and repairs a concurrent older
upload on a subsequent sync. The main rating sync continues to use its
independent merge rules. Drive operations time out after 30 seconds and are
retried on a later sync occasion.

If the password is forgotten, the existing encrypted content cannot be
recovered. After entering the API keys again, the user can explicitly
confirm replacing the encrypted file with a new password. This is separate
from a normal unlock attempt: a wrong password never overwrites Drive data.

Algorithm API references: [Argon2id](https://pub.dev/documentation/cryptography/latest/cryptography/Argon2id-class.html)
and [cryptography](https://pub.dev/documentation/cryptography/latest/).
