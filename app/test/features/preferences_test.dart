import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/app/ratings_preferences.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/work_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'floating navigation defaults on and classic choice survives restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      ProviderContainer create() => ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      final first = create();
      expect(first.read(floatingNavigationProvider), isTrue);
      await first.read(floatingNavigationProvider.notifier).set(false);
      first.dispose();
      final restarted = create();
      addTearDown(restarted.dispose);
      expect(restarted.read(floatingNavigationProvider), isFalse);
    },
  );
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  ProviderContainer open(SharedPreferences preferences) {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('unknown saved settings fall back to supported defaults', () async {
    final container = open(
      await prefs({
        'theme_mode': 'obsolete',
        'locale': 'fr',
        'divergence_source': 'rt',
      }),
    );
    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(container.read(localeProvider), isNull);
    expect(container.read(ratingsViewProvider).compareWith, RatingSource.kp);
  });

  test('theme and explicit language survive a new container', () async {
    final preferences = await prefs({});
    final first = open(preferences);
    await first.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await first.read(localeProvider.notifier).set(const Locale('ru'));
    final restarted = open(preferences);
    expect(restarted.read(themeModeProvider), ThemeMode.dark);
    expect(restarted.read(localeProvider), const Locale('ru'));
    expect(restarted.read(contentLanguageProvider), 'ru-RU');
    await restarted.read(localeProvider.notifier).set(null);
    expect(preferences.containsKey('locale'), isFalse);
    expect(open(preferences).read(localeProvider), isNull);
  });

  testWidgets('system language follows supported device locales and changes', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [
      Locale('fr'),
      Locale('ru'),
    ];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final container = open(await prefs({}));
    final subscription = container.listen(contentLanguageProvider, (_, _) {});
    addTearDown(subscription.close);
    expect(container.read(contentLanguageProvider), 'ru-RU');
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    await tester.pump();
    expect(container.read(contentLanguageProvider), 'en-US');
    await container.read(localeProvider.notifier).set(const Locale('ru'));
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    await tester.pump();
    expect(container.read(contentLanguageProvider), 'ru-RU');
    subscription.close();
    container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });

  test(
    'list controls preserve one another; only comparison source persists',
    () async {
      final preferences = await prefs({});
      final container = open(preferences);
      final controls = container.read(ratingsViewProvider.notifier);
      controls.filter(WorkKind.season);
      controls.sortBy(RatingsSort.divergence);
      controls.orderBy(DivergenceOrder.lower);
      await controls.compareWith(RatingSource.imdb);
      expect(container.read(ratingsViewProvider), (
        kind: WorkKind.season,
        sort: RatingsSort.divergence,
        compareWith: RatingSource.imdb,
        order: DivergenceOrder.lower,
      ));
      controls.filter(null);
      expect(container.read(ratingsViewProvider).sort, RatingsSort.divergence);
      expect(container.read(ratingsViewProvider).order, DivergenceOrder.lower);
      expect(open(preferences).read(ratingsViewProvider), (
        kind: null,
        sort: RatingsSort.scoredAt,
        compareWith: RatingSource.imdb,
        order: DivergenceOrder.furthest,
      ));
    },
  );
}
