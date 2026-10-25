# Sync and backup

How user data moves between devices and how not to lose it. There is no
server — the user's own Google Drive plays the shared storage. What exactly
is synced is in [data-model.md](data-model.md).

**Status: implemented in Stage 5** (`app/lib/data/sync/`); waiting for the
Google Cloud project to be used on phones. When this file and the code
disagree, the code is right.

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
  "format_version": 1,
  "written_at": 1760870400000,
  "written_by": "6f1c…-device-uuid",
  "app_version": "0.5.0+5",
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
- The file gets every `ratings` and `watchlist` row, tombstones included, and
  the `works` rows they refer to, with their ancestors.
- API keys, settings and the rating cache never go into the file.

---

## Merging

Every `ratings` and `watchlist` row is an LWW register (last write wins) keyed
by `work_key`. The version with the larger `(updated_at, updated_by)` wins:
time first, and on a tie the lexicographically larger `device_id`. A
tombstone is an ordinary version of the row and wins or loses by the same
rules. `works` rows merge the same way, by `snapshot_updated_at`.

This merge is **commutative, associative and idempotent**: whatever order and
however many times the devices synced, the states converge. This property is
the main thing the rest of the algorithm rests on, and it is covered by tests
on random sequences of edits (property-based).

### One pass of the algorithm

1. Find the file: `files.list` in `spaces=appDataFolder` by name. If there
   are several files with that name (two devices created the first file at
   the same time), merge them all, keep the oldest, delete the rest.
2. Download the content (`alt=media`) and remember `modifiedTime`.
3. Check `format_version`.
4. Merge the remote state with the local one. Write the rows where the remote
   version won to the local database in **one transaction**.
5. If the merged state has rows where the local version won (that is, the
   remote differs from the merged), upload the merged state. Before
   uploading, re-read the file's metadata: if `modifiedTime` changed after
   step 2, go back to step 2 (at most three attempts).
6. Write `last_sync_at` and `modifiedTime` to `sync_state`.

Drive API v3 has no conditional write (If-Match) for content upload, so a
race window remains between steps 5 and 6: another device may overwrite the
file without seeing our upload. That doesn't lose data: the losing device
kept its rows locally, and on the next sync step 5 uploads them again. The
race delays a change but doesn't lose it. That is exactly why every device
keeps the full state.

### When to sync

- on app launch and on returning to it, if more than 5 minutes have passed
  since the last sync;
- 30 seconds after the last change (debounce);
- with the "Sync" button in settings.

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

In the MVP they are kept forever. A rating is about 300 bytes of JSON, so
even 5,000 rows with notes take hundreds of kilobytes after gzip. Cleaning up
old tombstones is only possible with a rule like "a device that hasn't
synced for more than N days replaces rather than merges on its next
sign-in" — that is in [future-development.md](future-development.md).

---

## First sign-in and sign-out

- **First sign-in on a device with local data, when Drive already has a
  file**, is an ordinary merge, not a replacement. Before it there is a
  dialog with counters: "120 ratings on the device, 340 in Drive, 395 after
  merging".
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
