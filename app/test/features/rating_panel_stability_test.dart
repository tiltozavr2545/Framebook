import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/ratings_service.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/title/ratings_panel.dart';
import 'package:framebook/features/title/title_ratings.dart';
import 'package:framebook/l10n/app_localizations.dart';

class _View extends TitleRatings {
  _View(super.target, this.input);
  final ValueNotifier<RatingsView> input;
  @override
  RatingsView build() {
    void update() => state = input.value;
    input.addListener(update);
    ref.onDispose(() => input.removeListener(update));
    return input.value;
  }
}

void main() {
  for (final scale in [1.0, 1.8, 3.0]) {
    testWidgets(
      'source panel stays the same height when captions arrive at scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final db = AppDatabase(NativeDatabase.memory());
        final input = ValueNotifier(const RatingsView());
        const target = RatingTarget(
          key: WorkKey.movie(1),
          tmdbVote: TmdbVote(10, 1),
        );
        const marker = ValueKey('below-ratings');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              titleRatingsProvider(
                target,
              ).overrideWith(() => _View(target, input)),
              ratingsServiceProvider.overrideWithValue(RatingsService(db)),
              myRatingProvider.overrideWith((ref, key) => Stream.value(null)),
            ],
            child: MaterialApp(
              theme: FramebookTheme.light,
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (_, child) => MediaQuery(
                data: MediaQueryData(
                  size: const Size(360, 900),
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        RatingsPanel(target: target),
                        SizedBox(key: marker, height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 1));
        final before = tester.getTopLeft(find.byKey(marker)).dy;
        input.value = RatingsView(
          rows: {
            for (final source in RatingSource.values)
              source: ExternalRating(
                workKey: 'tmdb:movie:1',
                source: source,
                status: RatingStatus.ok,
                value:
                    source == RatingSource.rt ||
                        source == RatingSource.metacritic
                    ? 100
                    : 10,
                votes: 1234567,
                scale:
                    source == RatingSource.rt ||
                        source == RatingSource.metacritic
                    ? 100
                    : 10,
                via: source == RatingSource.tmdb
                    ? ApiSource.tmdb
                    : source == RatingSource.kp
                    ? ApiSource.poiskkino
                    : ApiSource.omdb,
                fetchedAt: 1,
              ),
          },
        );
        await tester.pump();
        expect(tester.getTopLeft(find.byKey(marker)).dy, before);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 1));
        input.dispose();
        await db.close();
      },
    );
  }
}
