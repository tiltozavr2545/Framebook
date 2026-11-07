import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'library.dart';
import '../db/database.dart';

bool _sameTasteWork(Work? a, Work? b) =>
    identical(a, b) ||
    a != null &&
        b != null &&
        a.workKey == b.workKey &&
        a.kind == b.kind &&
        a.tmdbId == b.tmdbId &&
        a.title == b.title &&
        a.year == b.year &&
        a.genreIds == b.genreIds;

/// Recommendation inputs exclude external-rating refreshes and note edits.
class TasteRatings extends Notifier<List<RatedTitle>> {
  @override
  List<RatedTitle> build() =>
      ref.watch(ratedTitlesProvider).value ?? const <RatedTitle>[];

  @override
  bool updateShouldNotify(List<RatedTitle> previous, List<RatedTitle> next) {
    if (previous.length != next.length) return true;
    for (var i = 0; i < next.length; i++) {
      final a = previous[i];
      final b = next[i];
      if (a.rating.scoreHalf != b.rating.scoreHalf ||
          a.rating.deletedAt != b.rating.deletedAt ||
          !_sameTasteWork(a.work, b.work) ||
          !_sameTasteWork(a.series, b.series) ||
          !_sameTasteWork(a.season, b.season)) {
        return true;
      }
    }
    return false;
  }
}

final tasteRatingsProvider =
    NotifierProvider.autoDispose<TasteRatings, List<RatedTitle>>(
      TasteRatings.new,
    );
