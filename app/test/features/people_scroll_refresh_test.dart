import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/library/favorite_people.dart';
import 'package:framebook/data/library/insights.dart';
import 'package:framebook/data/library/insights_provider.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/people_index.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/features/search/people_shelves.dart';
import 'package:framebook/l10n/app_localizations.dart';

import '../data/insights_test.dart' show rated;

class _Insights extends Notifier<LibraryInsights> {
  @override
  LibraryInsights build() => emptyLibraryInsights;
  void publish(LibraryInsights value) => state = value;
}

final _insights = NotifierProvider<_Insights, LibraryInsights>(_Insights.new);

class _Index extends PeopleIndex {
  @override
  PeopleIndexState build() =>
      const PeopleIndexState(total: 1, entries: {'known': []});
  void publish(PeopleIndexState value) => state = value;
}

void main() {
  testWidgets(
    'people refresh cannot collapse shelves and reset vertical scroll',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final rows = [rated(1, 16)];
      final populated = LibraryInsights(
        genres: const {},
        decades: const {},
        duos: const [],
        covered: 1,
        people: [
          for (var id = 1; id <= 8; id++)
            PersonInsight(
              PeopleCredit(
                id: id,
                name: 'Person $id',
                role: FilmographyRole.acting,
              ),
              rows,
              {for (final role in FilmographyRole.values) role: rows},
            ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          ratedTitlesProvider.overrideWith((ref) => Stream.value(rows)),
          favoritePeopleProvider.overrideWith((ref) => Stream.value([])),
          peopleIndexProvider.overrideWith(_Index.new),
          libraryInsightsProvider.overrideWith(
            (ref, kind) => ref.watch(_insights),
          ),
          popularPeopleProvider.overrideWith(
            (ref) async => const [PersonSummary(id: 99, name: 'Popular')],
          ),
        ],
      );
      container.read(_insights.notifier).publish(populated);
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: FramebookTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: PeopleShelves()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        scroll.position.jumpTo(800);
        await tester.pumpAndSettle();
        final before = scroll.position.pixels;
        expect(before, 800);
        final index = container.read(peopleIndexProvider.notifier) as _Index;
        index.publish(const PeopleIndexState(running: true, total: 1));
        container.read(_insights.notifier).publish(emptyLibraryInsights);
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(scroll.position.pixels, before);
        container
            .read(_insights.notifier)
            .publish(
              LibraryInsights(
                genres: const {},
                decades: const {},
                duos: const [],
                covered: 1,
                people: [
                  PersonInsight(
                    const PeopleCredit(
                      id: 1,
                      name: 'Partial',
                      role: FilmographyRole.acting,
                    ),
                    rows,
                    {FilmographyRole.acting: rows},
                  ),
                ],
              ),
            );
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(scroll.position.pixels, before);
        container.read(_insights.notifier).publish(populated);
        index.publish(const PeopleIndexState(total: 1, entries: {'known': []}));
        await tester.pumpAndSettle();
        expect(scroll.position.pixels, before);
        container.read(_insights.notifier).publish(emptyLibraryInsights);
        await tester.pumpAndSettle();
        expect(scroll.position.maxScrollExtent, 0);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await tester.pump(const Duration(milliseconds: 1));
      }
    },
  );
}
