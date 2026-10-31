import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../db/database.dart';
import '../db/database_provider.dart';
import '../library/library.dart';
import 'google_account.dart';
import 'merge.dart';
import 'sync_engine.dart';
import 'sync_file.dart';
import 'sync_store.dart';

/// What the Sync and backup screen shows.
final class SyncStatus {
  const SyncStatus({
    required this.configured,
    this.account,
    this.busy = false,
    this.lastSyncAt,
    this.error,
    this.stale,
    this.staleFingerprint,
  });

  /// Whether this build can sign in to Google at all.
  final bool configured;

  /// The signed-in email; `null` — sync is off.
  final String? account;
  final bool busy;

  /// UTC ms of the last successful sync.
  final int? lastSyncAt;

  /// How the last attempt failed; `null` after a success. Offline is not
  /// kept: it is quietly put off (docs/sync.md, "Errors").
  final SyncFailure? error;

  /// Sync is paused on a question: this many of this device's ratings and
  /// watchlist entries, changed and never synced, are older than Drive's
  /// watermark, and the user keeps or discards them
  /// ([SyncController.resolveStale]). `null` — nothing to ask.
  final int? stale;
  final String? staleFingerprint;

  SyncStatus copyWith({
    String? Function()? account,
    bool? busy,
    int? Function()? lastSyncAt,
    SyncFailure? Function()? error,
    int? Function()? stale,
    String? Function()? staleFingerprint,
  }) => SyncStatus(
    configured: configured,
    account: account == null ? this.account : account(),
    busy: busy ?? this.busy,
    lastSyncAt: lastSyncAt == null ? this.lastSyncAt : lastSyncAt(),
    error: error == null ? this.error : error(),
    stale: stale == null ? this.stale : stale(),
    staleFingerprint: staleFingerprint == null
        ? this.staleFingerprint
        : staleFingerprint(),
  );
}

/// The counters of the first sign-in dialog (docs/sync.md, "First sign-in").
typedef FirstSync = ({int device, int drive, int merged});

/// The app version written into the file; read from the platform in `main()`.
final appVersionProvider = Provider<String>((ref) => 'unknown');

/// The result of reading an import file, for its dialog. [stale] — live
/// rows of this device's, never synced, that merging would drop: the dialog
/// asks whether to keep them.
typedef ImportPreview = ({
  SyncState file,
  int device,
  int inFile,
  int merged,
  int stale,
  String fingerprint,
});

final syncDebounceProvider = Provider<Duration>(
  (ref) => SyncController.debounce,
);

/// Sync with Google Drive, the daily copies, export and import
/// (docs/sync.md). Syncs on launch and on returning to the app when the last
/// sync is more than [resumeAfter] old, [debounce] after a change, and on the
/// button.
class SyncController extends Notifier<SyncStatus> {
  static const resumeAfter = Duration(minutes: 5);
  static const debounce = Duration(seconds: 30);

  static const _accountKey = 'sync_account';
  static const _errorKey = 'last_sync_error';

  late GoogleAccount _google;
  late SyncStore _store;
  Timer? _debounce;
  Future<void>? _running;
  bool _changedDuringSync = false;
  bool _suspended = false;
  bool _firstSyncPending = false;
  bool _sessionReady = false;

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  SyncStatus build() {
    _google = ref.watch(googleAccountProvider);
    _store = SyncStore(ref.watch(databaseProvider));
    final prefs = ref.watch(sharedPreferencesProvider);
    final account = _google.configured ? prefs.getString(_accountKey) : null;

    final changes = _db
        .tableUpdates(
          TableUpdateQuery.onAllTables([_db.ratings, _db.watchlist]),
        )
        .listen((_) => _changed());
    final lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_restoreAndMaybeSync()),
    );
    ref.onDispose(() {
      changes.cancel();
      lifecycle.dispose();
      _debounce?.cancel();
    });

    unawaited(_load(account));
    return SyncStatus(configured: _google.configured, account: account);
  }

  /// Reads the last sync from `sync_state`, then — if signed in — restores
  /// the session silently and syncs if it is due.
  Future<void> _load(String? account) async {
    final last = int.tryParse(
      await _store.stateValue(SyncStore.lastSyncKey) ?? '',
    );
    final error = await _store.stateValue(_errorKey);
    if (!ref.mounted) return;
    state = state.copyWith(
      lastSyncAt: () => last,
      error: () => SyncFailure.values.where((f) => f.name == error).firstOrNull,
    );
    if (account == null) return;
    await _restoreAndMaybeSync();
  }

  Future<void> _restoreAndMaybeSync() async {
    if (state.account == null || _suspended) return;
    final restored = await _google.restore();
    if (!ref.mounted || restored == null) return;
    _sessionReady = true;
    await _maybeSync();
  }

  Future<void> _maybeSync() async {
    if (state.account == null ||
        !_sessionReady ||
        _suspended ||
        _firstSyncPending) {
      return;
    }
    final last = state.lastSyncAt;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (last != null && now - last < resumeAfter.inMilliseconds) return;
    await sync();
  }

  void _changed() {
    if (state.account == null || !_sessionReady || _firstSyncPending) return;
    if (_suspended || state.busy) {
      _changedDuringSync = true;
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(ref.read(syncDebounceProvider), () => unawaited(sync()));
  }

  /// Signs in. When Drive already has data and so does the device, returns
  /// the counters for the merge dialog, and nothing is synced until
  /// [confirmFirstSync]; otherwise syncs at once and returns `null`. Throws
  /// [SignInException] and [SyncException].
  Future<FirstSync?> signIn() async {
    final email = await _google.signIn();
    _sessionReady = true;
    final drive = await _withDrive((engine) => engine.peek());
    final device = await _store.read();
    final hasLocalData =
        device.liveRatings != 0 ||
        device.watchlist.any((entry) => entry.deletedAt == null);
    _firstSyncPending = drive != null && hasLocalData;
    if (!_firstSyncPending) {
      await ref.read(sharedPreferencesProvider).setString(_accountKey, email);
    } else {
      await ref.read(sharedPreferencesProvider).remove(_accountKey);
    }
    state = state.copyWith(account: () => email, error: () => null);
    if (!_firstSyncPending) {
      await sync();
      return null;
    }
    final remote = drive!;
    return (
      device: device.liveRatings,
      drive: remote.liveRatings,
      merged: mergeStates(device, remote).liveRatings,
    );
  }

  Future<void> confirmFirstSync() async {
    final account = state.account;
    if (!_firstSyncPending || account == null) return;
    await ref.read(sharedPreferencesProvider).setString(_accountKey, account);
    _firstSyncPending = false;
    await sync();
  }

  /// One sync pass; a pass already under way is waited for instead. Errors
  /// end up in [SyncStatus.error], never thrown; a question about stale
  /// changes, in [SyncStatus.stale].
  Future<void> sync() => _pass(null, null);

  /// The answer to [SyncStatus.stale]: runs the pass again with it.
  Future<void> resolveStale({
    required bool keep,
    required String fingerprint,
  }) => _pass(keep ? StaleChoice.keep : StaleChoice.discard, fingerprint);

  Future<void> _pass(StaleChoice? stale, String? fingerprint) =>
      _suspended || _firstSyncPending
      ? Future.value()
      : _running == null
      ? _running = _sync(stale, fingerprint).whenComplete(() {
          _running = null;
        })
      : stale == null
      ? _running!
      : _running!.then((_) => _pass(stale, fingerprint));

  Future<void> _sync(StaleChoice? stale, String? fingerprint) async {
    if (state.account == null) return;
    _debounce?.cancel();
    _changedDuringSync = false;
    state = state.copyWith(busy: true);
    try {
      final report = await _withDrive(
        (engine) => engine.sync(stale: stale, reviewedFingerprint: fingerprint),
      );
      if (report.paused) {
        if (ref.mounted) {
          state = state.copyWith(
            stale: () => report.stale,
            staleFingerprint: () => report.staleFingerprint,
          );
        }
        return;
      }
      _changedDuringSync = report.pendingChanges;
      await _store.setStateValue(_errorKey, null);
      if (ref.mounted) {
        state = state.copyWith(
          lastSyncAt: () => report.syncedAt,
          error: () => null,
          stale: () => null,
          staleFingerprint: () => null,
        );
      }
    } on SyncException catch (e) {
      await _fail(e.failure);
    } finally {
      if (ref.mounted) {
        state = state.copyWith(busy: false);
        if (_changedDuringSync && state.stale == null) _changed();
      }
    }
  }

  Future<void> _fail(SyncFailure failure) async {
    // No connection is not an error worth showing: the next occasion retries.
    if (failure == SyncFailure.offline) return;
    await _store.setStateValue(_errorKey, failure.name);
    if (ref.mounted) state = state.copyWith(error: () => failure);
  }

  /// Runs [action] with Drive access; once Drive says the token expired,
  /// drops it and tries again with a fresh one.
  Future<T> _withDrive<T>(Future<T> Function(SyncEngine engine) action) async {
    var access = await _google.drive();
    try {
      return await action(_engine(access.remote));
    } on SyncException catch (e) {
      if (e.failure != SyncFailure.unauthorized) rethrow;
      await access.expire();
      access = await _google.drive();
      return action(_engine(access.remote));
    }
  }

  SyncEngine _engine(SyncRemote remote) => SyncEngine(
    _store,
    remote,
    deviceId: ref.read(deviceIdProvider),
    appVersion: ref.read(appVersionProvider),
  );

  /// Signing out keeps the data, both here and in Drive.
  Future<void> signOut() async {
    _suspended = true;
    _debounce?.cancel();
    try {
      await _running;
      await _signOut();
    } finally {
      _suspended = false;
      if (ref.mounted && _changedDuringSync) _changed();
    }
  }

  Future<void> _signOut() async {
    await _google.signOut();
    await ref.read(sharedPreferencesProvider).remove(_accountKey);
    await _store.setStateValue(_errorKey, null);
    _firstSyncPending = false;
    _sessionReady = false;
    state = state.copyWith(
      account: () => null,
      error: () => null,
      stale: () => null,
      staleFingerprint: () => null,
    );
  }

  /// Deletes the file and the daily copies from Drive and signs out here.
  /// Throws [SyncException].
  Future<void> deleteDriveData() async {
    _suspended = true;
    _debounce?.cancel();
    try {
      await _running;
      await _withDrive((engine) => engine.deleteAll());
      await _store.setStateValue(SyncStore.lastSyncKey, null);
      await _store.setStateValue(SyncStore.modifiedKey, null);
      state = state.copyWith(lastSyncAt: () => null);
      await _signOut();
    } finally {
      _suspended = false;
      if (ref.mounted && _changedDuringSync) _changed();
    }
  }

  /// The daily copies, newest first. Throws [SyncException].
  Future<List<RemoteFile>> backups() =>
      _withDrive((engine) => engine.backups());

  /// Restoring a daily copy is an import that replaces everything (its
  /// watermark clamped as the file's is). Throws [SyncException].
  Future<void> restore(RemoteFile backup) async {
    final copy = await _withDrive((engine) => engine.readBackup(backup));
    await _replace(copy);
  }

  /// The export file: the same format as the file in Drive.
  Future<List<int>> export() async => SyncFile.encode(
    await _store.read(),
    writtenAt: _now,
    writtenBy: ref.read(deviceIdProvider),
    appVersion: ref.read(appVersionProvider),
  );

  /// Reads an import file; its watermark is clamped to this device's clock,
  /// as Drive's is. Throws [SyncFileException].
  Future<ImportPreview> previewImport(List<int> bytes) async {
    final read = SyncFile.decode(bytes);
    final file = read.withPurgedBefore(clampWatermark(read.purgedBefore, _now));
    return _preview(file);
  }

  Future<ImportPreview> _preview(SyncState file) async {
    final device = await _store.read();
    final lastSyncAt = int.tryParse(
      await _store.stateValue(SyncStore.lastSyncKey) ?? '',
    );
    final stale = unsyncedDrops(device, file, lastSyncAt: lastSyncAt);
    return (
      file: file,
      device: device.liveRatings,
      inFile: file.liveRatings,
      merged: mergeStates(device, file).liveRatings,
      stale: stale.ratings.length + stale.watchlist.length,
      fingerprint: staleFingerprint(device, file, lastSyncAt: lastSyncAt),
    );
  }

  /// Returns an updated preview when newly discovered conflicts need consent.
  Future<ImportPreview?> import(
    SyncState file, {
    required bool replace,
    bool keepStale = true,
    String? reviewedFingerprint,
  }) async {
    if (replace) {
      await _replace(file);
    } else {
      final updated = await _db.transaction(() async {
        final device = await _store.read();
        final lastSyncAt = int.tryParse(
          await _store.stateValue(SyncStore.lastSyncKey) ?? '',
        );
        final stale = unsyncedDrops(device, file, lastSyncAt: lastSyncAt);
        final count = stale.ratings.length + stale.watchlist.length;
        if (count > 0 &&
            staleFingerprint(device, file, lastSyncAt: lastSyncAt) !=
                reviewedFingerprint) {
          return _preview(file);
        }
        if (keepStale && count > 0) {
          await _store.restamp(
            ratings: stale.ratings,
            watchlist: stale.watchlist,
            deviceId: ref.read(deviceIdProvider),
            now: _now,
            remote: file,
          );
        }
        await _store.apply(file);
        return null;
      });
      if (updated != null) return updated;
      if (state.account != null) unawaited(sync());
    }
    return null;
  }

  static int get _now => DateTime.now().toUtc().millisecondsSinceEpoch;

  Future<void> _replace(SyncState file) async {
    await _store.replaceWith(
      file,
      deviceId: ref.read(deviceIdProvider),
      now: _now,
    );
    if (state.account != null) unawaited(sync());
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);
