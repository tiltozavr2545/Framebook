import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../work_key.dart';

const _hiddenKey = 'recommendation_hidden';

/// A per-device discovery preference, like search history. It changes no
/// score/watchlist row and is not interpreted as a negative taste signal.
class HiddenRecommendations extends Notifier<Set<WorkKey>> {
  Future<void> _writes = Future.value();
  int _revision = 0;
  Set<WorkKey> _persisted = const {};
  @override
  Set<WorkKey> build() => _persisted = Set.unmodifiable({
    for (final raw
        in ref.watch(sharedPreferencesProvider).getStringList(_hiddenKey) ??
            <String>[])
      if (WorkKey.tryParse(raw) case final key?) key,
  });

  Future<void> _save(Set<WorkKey> next) {
    final prefs = ref.read(sharedPreferencesProvider);
    final revision = ++_revision;
    state = Set.unmodifiable(next);
    final strings = next.map((key) => key.toString()).toList()..sort();
    // Serialize writes so rapid hide/undo actions cannot persist out of order.
    final write = _writes.then((_) async {
      if (!await prefs.setStringList(_hiddenKey, strings)) {
        throw StateError('Could not save hidden recommendations');
      }
      _persisted = Set.unmodifiable(next);
    });
    _writes = write.catchError((Object _) {});
    return write.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        if (ref.mounted && revision == _revision) state = _persisted;
        Error.throwWithStackTrace(error, stack);
      },
    );
  }

  Future<void> hide(WorkKey key) => _save({...state, key});
  Future<void> restore(WorkKey key) => _save({...state}..remove(key));
  Future<void> clear() => _save({});
}

final hiddenRecommendationsProvider =
    NotifierProvider<HiddenRecommendations, Set<WorkKey>>(
      HiddenRecommendations.new,
    );
