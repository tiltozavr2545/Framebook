import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/app/ratings_preferences.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/settings/settings_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _Write = ({String key, Object? value, Completer<bool> result});

class _Preferences implements SharedPreferences {
  final values = <String, Object>{
    'theme_mode': 'system',
    'locale': 'en',
    'floating_navigation': true,
    'divergence_source': 'kp',
  };
  final writes = <_Write>[];
  bool closed = false;

  @override
  String? getString(String key) => values[key] as String?;
  @override
  bool? getBool(String key) => values[key] as bool?;

  Future<bool> _write(String key, Object? value) async {
    if (closed) return false;
    final result = Completer<bool>();
    writes.add((key: key, value: value, result: result));
    final accepted = await result.future;
    if (accepted) {
      if (value == null) {
        values.remove(key);
      } else {
        values[key] = value;
      }
    }
    return accepted;
  }

  @override
  Future<bool> setString(String key, String value) => _write(key, value);
  @override
  Future<bool> setBool(String key, bool value) => _write(key, value);
  @override
  Future<bool> remove(String key) => _write(key, null);

  void close() {
    closed = true;
    for (final write in writes) {
      if (!write.result.isCompleted) write.result.complete(false);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _change(ProviderContainer container, String kind, bool last) =>
    switch (kind) {
      'theme' =>
        container
            .read(themeModeProvider.notifier)
            .set(last ? ThemeMode.dark : ThemeMode.light),
      'locale' =>
        container
            .read(localeProvider.notifier)
            .set(last ? null : const Locale('ru')),
      'navigation' =>
        container.read(floatingNavigationProvider.notifier).set(last),
      _ =>
        container
            .read(ratingsViewProvider.notifier)
            .compareWith(last ? RatingSource.kp : RatingSource.imdb),
    };

Object? _read(ProviderContainer container, String kind) => switch (kind) {
  'theme' => container.read(themeModeProvider),
  'locale' => container.read(localeProvider),
  'navigation' => container.read(floatingNavigationProvider),
  _ => container.read(ratingsViewProvider).compareWith,
};

Object? _value(String kind, bool last) => switch (kind) {
  'theme' => last ? ThemeMode.dark : ThemeMode.light,
  'locale' => last ? null : const Locale('ru'),
  'navigation' => last,
  _ => last ? RatingSource.kp : RatingSource.imdb,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a failed pending write does not update a disposed notifier', () async {
    final prefs = _Preferences();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    final change = container
        .read(themeModeProvider.notifier)
        .set(ThemeMode.dark);
    final outcome = expectLater(change, throwsStateError);
    await pumpEventQueue();
    container.dispose();
    prefs.writes.single.result.complete(false);
    await outcome;
    prefs.close();
  });
  for (final kind in ['theme', 'locale', 'navigation', 'source']) {
    for (final firstAccepted in [false, true]) {
      test(
        '$kind writes serialize and recover after failure: first saved=$firstAccepted',
        () async {
          final prefs = _Preferences();
          final container = ProviderContainer(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          );
          addTearDown(() async {
            prefs.close();
            await pumpEventQueue();
            container.dispose();
          });
          final initial = _read(container, kind);
          final first = _change(container, kind, false);
          final last = _change(container, kind, true);
          final firstOutcome = firstAccepted
              ? first
              : expectLater(first, throwsStateError);
          final lastOutcome = expectLater(last, throwsStateError);
          if (kind == 'source') {
            container.read(ratingsViewProvider.notifier)
              ..filter(WorkKind.season)
              ..sortBy(RatingsSort.divergence)
              ..orderBy(DivergenceOrder.lower);
          }
          await pumpEventQueue();
          expect(prefs.writes, hasLength(1));
          prefs.writes.first.result.complete(firstAccepted);
          await pumpEventQueue();
          expect(prefs.writes, hasLength(2));
          expect(_read(container, kind), _value(kind, true));
          prefs.writes.last.result.completeError(
            StateError('Storage unavailable'),
          );
          await Future.wait([firstOutcome, lastOutcome]);
          expect(
            _read(container, kind),
            firstAccepted ? _value(kind, false) : initial,
          );
          if (kind == 'source') {
            expect(container.read(ratingsViewProvider).kind, WorkKind.season);
            expect(
              container.read(ratingsViewProvider).sort,
              RatingsSort.divergence,
            );
            expect(
              container.read(ratingsViewProvider).order,
              DivergenceOrder.lower,
            );
          }
          final retry = _change(container, kind, false);
          await pumpEventQueue();
          prefs.writes.last.result.complete(true);
          await retry;
          final restarted = ProviderContainer(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          );
          addTearDown(restarted.dispose);
          expect(_read(restarted, kind), _value(kind, false));
        },
      );
    }
  }

  testWidgets(
    'Settings reports rejected persistence and restores the selection',
    (tester) async {
      final prefs = _Preferences();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(() async {
        prefs.close();
        await pumpEventQueue();
        container.dispose();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FramebookTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
      tester
          .widget<DropdownButton<ThemeMode>>(
            find.byType(DropdownButton<ThemeMode>),
          )
          .onChanged!(ThemeMode.dark);
      await tester.pump();
      prefs.writes.single.result.complete(false);
      await tester.pumpAndSettle();
      expect(
        find.text('Could not save this preference. Try again.'),
        findsOneWidget,
      );
      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('a rejected preference write restores the last saved theme', () async {
    final prefs = _Preferences();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(() async {
      prefs.close();
      await pumpEventQueue();
      container.dispose();
    });
    final change = container
        .read(themeModeProvider.notifier)
        .set(ThemeMode.dark);
    final failure = expectLater(change, throwsStateError);
    await pumpEventQueue();
    prefs.writes.single.result.complete(false);
    await failure;
    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}
