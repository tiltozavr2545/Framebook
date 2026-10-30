import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import '../../app/preferences.dart';
import '../../features/ratings/ratings_screen.dart';
import '../api_keys.dart';
import '../api_source.dart';
import '../library/library.dart';
import 'google_account.dart';
import 'secrets_vault.dart';
import 'sync_controller.dart';

final secretsStorageProvider = Provider<KeyStorage>(
  (ref) => SecureKeyStorage(),
);

final class SecretsMissing implements Exception {
  const SecretsMissing();
}

final class SecretsStatus {
  const SecretsStatus({
    this.enabled = false,
    this.locked = false,
    this.busy = false,
    this.error,
  });
  final bool enabled;
  final bool locked;
  final bool busy;
  final Object? error;
  SecretsStatus copyWith({
    bool? enabled,
    bool? locked,
    bool? busy,
    Object? Function()? error,
  }) => SecretsStatus(
    enabled: enabled ?? this.enabled,
    locked: locked ?? this.locked,
    busy: busy ?? this.busy,
    error: error == null ? this.error : error(),
  );
}

class SecretsController extends Notifier<SecretsStatus> {
  Map<ApiSource, StoredKey>? _remoteKeys;
  RatingSource? _remoteSource;
  bool _dirty = false;
  Future<void>? _running;
  String? _account;
  int _epoch = 0;
  int _revision = 0;
  final Set<Future<void>> _operations = {};
  Future<void> _track(Future<void> Function() action) {
    final operation = action();
    _operations.add(operation);
    return operation.whenComplete(() {
      _operations.remove(operation);
    });
  }

  bool _valid(String? account, int epoch) =>
      ref.mounted && _account == account && _epoch == epoch;
  String _enabledKey(String account) => 'secrets_enabled.$account';

  @override
  SecretsStatus build() {
    _account = ref.read(syncControllerProvider).account;
    ref.listen(syncControllerProvider, (previous, next) {
      if (previous?.account != next.account) {
        _epoch++;
        _account = next.account;
        unawaited(_load());
      }
    });
    ref.listen(apiKeysProvider, (_, keys) {
      final expected = _remoteKeys;
      if (expected != null &&
          ApiSource.values.every((source) {
            final a = keys[source], b = expected[source];
            return a?.value == b?.value && a?.verified == b?.verified;
          })) {
        return;
      }
      _changed();
    });
    ref.listen(ratingsViewProvider, (old, next) {
      if (old?.compareWith != next.compareWith &&
          next.compareWith != _remoteSource) {
        _changed();
      }
    });
    final lifecycle = AppLifecycleListener(
      onResume: () {
        if (state.enabled) unawaited(_load());
      },
    );
    ref.onDispose(lifecycle.dispose);
    scheduleMicrotask(() {
      if (ref.mounted) unawaited(_load());
    });
    return const SecretsStatus();
  }

  Future<SecretsVault> _vault([String? selectedAccount]) async {
    final account = selectedAccount ?? _account;
    if (account == null) throw StateError('No Google account');
    final access = await ref.read(googleAccountProvider).drive();
    return SecretsVault(
      remote: access.remote,
      storage: ref.read(secretsStorageProvider),
      accountId: account,
      deviceId: ref.read(deviceIdProvider),
    );
  }

  Future<void> _load() => _track(_loadImpl);

  Future<void> _loadImpl() async {
    final account = _account;
    final epoch = _epoch;
    final enabled =
        account != null &&
        (ref.read(sharedPreferencesProvider).getBool(_enabledKey(account)) ??
            false);
    if (!ref.mounted) return;
    state = SecretsStatus(enabled: enabled, locked: enabled);
    if (!enabled) return;
    try {
      final vault = await _vault(account);
      if (!_valid(account, epoch) ||
          !await vault.isUnlocked ||
          !_valid(account, epoch)) {
        return;
      }
      final revision = _revision;
      final snapshot = await vault.sync();
      if (!_valid(account, epoch)) return;
      if (_revision != revision) {
        state = state.copyWith(locked: false);
        _changed();
        return;
      }
      await _apply(snapshot, revision);
      if (_valid(account, epoch)) {
        state = state.copyWith(locked: false, error: () => null);
      }
    } catch (e) {
      if (_valid(account, epoch)) {
        state = state.copyWith(
          locked: e is SecretsLocked || e is SecretsWrongPassword,
          error: () => e,
        );
      }
    }
  }

  Future<void> _rememberEnabled(bool enabled, [String? selectedAccount]) async {
    final account = selectedAccount ?? _account;
    if (account == null) throw StateError('No Google account');
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_enabledKey(account), enabled);
  }

  Map<String, SecretsKey> _keys() {
    final keys = ref.read(apiKeysProvider);
    return {
      for (final source in ApiSource.values)
        if (keys[source] case final key?)
          source.name: SecretsKey(key.value, verified: key.verified),
    };
  }

  String? get _source => ref.read(ratingsViewProvider).compareWith.name;

  Future<void> enable(String password, {bool createIfMissing = true}) =>
      _track(() => _enable(password, createIfMissing: createIfMissing));

  Future<void> _enable(String password, {required bool createIfMissing}) async {
    _epoch++;
    final account = _account;
    final epoch = _epoch;
    if (account == null) throw StateError('No Google account');
    state = state.copyWith(busy: true, error: () => null);
    try {
      final vault = await _vault(account);
      if (!_valid(account, epoch)) return;
      final revision = _revision;
      final snapshot = await vault.unlock(password);
      if (!_valid(account, epoch) || _revision != revision) return;
      if (snapshot == null) {
        if (!createIfMissing) throw const SecretsMissing();
        await vault.save(_keys(), _source);
        if (!_valid(account, epoch)) return;
        await vault.sync(createIfMissing: true);
      } else {
        await _apply(snapshot, revision);
      }
      if (!_valid(account, epoch)) return;
      await _rememberEnabled(true, account);
      if (_valid(account, epoch)) {
        state = state.copyWith(enabled: true, locked: false);
      }
    } catch (e) {
      if (_valid(account, epoch)) state = state.copyWith(error: () => e);
      rethrow;
    } finally {
      if (_valid(account, epoch)) state = state.copyWith(busy: false);
    }
  }

  Future<void> overwrite(String password) => _track(() => _overwrite(password));

  Future<void> _overwrite(String password) async {
    _epoch++;
    final account = _account;
    final epoch = _epoch;
    if (account == null) throw StateError('No Google account');
    state = state.copyWith(busy: true, error: () => null);
    try {
      final vault = await _vault(account);
      if (!_valid(account, epoch)) return;
      await vault.save(_keys(), _source);
      if (!_valid(account, epoch)) return;
      await vault.overwrite(password);
      if (!_valid(account, epoch)) return;
      await _rememberEnabled(true, account);
      if (_valid(account, epoch)) {
        state = state.copyWith(enabled: true, locked: false);
      }
    } catch (e) {
      if (_valid(account, epoch)) state = state.copyWith(error: () => e);
      rethrow;
    } finally {
      if (_valid(account, epoch)) state = state.copyWith(busy: false);
    }
  }

  Future<void> disable() async {
    _epoch++;
    _dirty = false;
    final account = _account;
    final epoch = _epoch;
    if (account == null) return;
    state = const SecretsStatus();
    await _rememberEnabled(false, account);
    await SecretsVault.resetLocal(
      storage: ref.read(secretsStorageProvider),
      accountId: account,
    );
    if (_valid(account, epoch)) state = const SecretsStatus();
  }

  Future<void> prepareForDeletion() async {
    _epoch++;
    _dirty = false;
    final account = _account;
    if (account == null) return;
    state = const SecretsStatus();
    await _rememberEnabled(false, account);
    while (_operations.isNotEmpty) {
      await Future.wait(
        _operations.toList().map(
          (operation) => operation.catchError((Object _) {}),
        ),
      );
    }
  }

  Future<void> resetForDeletedDrive() async {
    _epoch++;
    if (_account == null) return;
    final account = _account;
    if (account == null) return;
    await _rememberEnabled(false, account);
    await SecretsVault.resetLocal(
      storage: ref.read(secretsStorageProvider),
      accountId: account,
    );
    if (ref.mounted) state = const SecretsStatus();
  }

  Future<void> _apply(SecretsSnapshot snapshot, int revision) async {
    final account = _account;
    final epoch = _epoch;
    final keys = <ApiSource, StoredKey>{
      for (final source in ApiSource.values)
        if (snapshot.keys[source.name] case final key?)
          source: StoredKey(key.value, verified: key.verified),
    };
    _remoteKeys = keys;
    try {
      await ref
          .read(apiKeysProvider.notifier)
          .replaceRemote(
            keys,
            stillValid: () => _valid(account, epoch) && _revision == revision,
          );
    } finally {
      _remoteKeys = null;
    }
    if (!_valid(account, epoch) || _revision != revision) return;
    final matches = RatingSource.values.where(
      (s) => s.name == snapshot.divergenceSource,
    );
    final source = matches.firstOrNull ?? RatingSource.kp;
    _remoteSource = source;
    try {
      await ref.read(ratingsViewProvider.notifier).compareWith(source);
    } finally {
      _remoteSource = null;
    }
  }

  void _changed() {
    _revision++;
    if (!state.enabled) return;
    _dirty = true;
    _running ??= _track(_upload).whenComplete(() {
      _running = null;
      if (_dirty && ref.mounted) _changed();
    });
  }

  Future<void> _upload() async {
    while (_dirty && ref.mounted && state.enabled) {
      _dirty = false;
      final account = _account;
      final epoch = _epoch;
      if (account == null) return;
      final keys = _keys();
      final source = _source;
      final revision = _revision;
      try {
        await SecretsVault.saveLocal(
          storage: ref.read(secretsStorageProvider),
          accountId: account,
          deviceId: ref.read(deviceIdProvider),
          keys: keys,
          divergenceSource: source,
        );
        if (!_valid(account, epoch) || !state.enabled || state.locked) return;
        final vault = await _vault(account);
        if (!_valid(account, epoch) || !state.enabled) return;
        final snapshot = await vault.sync();
        if (!_valid(account, epoch) || !state.enabled) return;
        if (!_dirty && _revision == revision) await _apply(snapshot, revision);
        if (_valid(account, epoch)) state = state.copyWith(error: () => null);
      } catch (e) {
        if (_valid(account, epoch)) {
          state = state.copyWith(
            locked: e is SecretsLocked || e is SecretsWrongPassword,
            error: () => e,
          );
        }
        return;
      }
    }
  }
}

final secretsControllerProvider =
    NotifierProvider<SecretsController, SecretsStatus>(SecretsController.new);
