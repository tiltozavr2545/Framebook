import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/recommendations/hidden.dart';
import 'package:framebook/data/work_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'rapid hide/undo writes persist in order and survive a new container',
    () async {
      SharedPreferences.setMockInitialValues({
        'recommendation_hidden': ['bad key'],
      });
      final prefs = await SharedPreferences.getInstance();
      ProviderContainer container() => ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      final first = container();
      addTearDown(first.dispose);
      expect(first.read(hiddenRecommendationsProvider), isEmpty);
      final hidden = first.read(hiddenRecommendationsProvider.notifier);
      await Future.wait([
        hidden.hide(const WorkKey.movie(1)),
        hidden.hide(const WorkKey.movie(2)),
        hidden.restore(const WorkKey.movie(1)),
      ]);
      final second = container();
      addTearDown(second.dispose);
      expect(second.read(hiddenRecommendationsProvider), {
        const WorkKey.movie(2),
      });
      await second.read(hiddenRecommendationsProvider.notifier).clear();
      expect(prefs.getStringList('recommendation_hidden'), isEmpty);
    },
  );
}
