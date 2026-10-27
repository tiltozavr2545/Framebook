import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/library/renumbering.dart';
import 'package:framebook/data/work_key.dart';

// Hand-made renumberings of a series 100: what TMDB now answers is a map of
// key → own id, what is stored is a rated key with the id saved with it.
void main() {
  WorkKey e(int season, int episode) => WorkKey.episode(100, season, episode);
  WorkKey s(int season) => WorkKey.season(100, season);
  RatedPart rated(WorkKey key, int id, [int score = 16]) =>
      RatedPart(key: key, tmdbId: id, scoreHalf: score);

  List<Renumbering> propose(List<RatedPart> rated, Map<WorkKey, int?> now) =>
      proposeRenumbering(rated: rated, current: now);

  /// Season 1 as TMDB first numbered it: E1…E4 with ids 11…14.
  final season1 = {for (var n = 1; n <= 4; n++) e(1, n): 10 + n};

  test('nothing moved — nothing to ask', () {
    expect(propose([rated(e(1, 2), 12), rated(e(1, 4), 14)], season1), isEmpty);
  });

  test('an unknown id (the series id stands in) is never moved', () {
    // E1 was saved without its own id; E1 is now another episode.
    expect(
      propose([rated(e(1, 1), 100)], {e(1, 1): 99, e(1, 2): 100}),
      isEmpty,
    );
  });

  test('a special moved in front: the rating follows its episode', () {
    // TMDB put a pilot at E1, everything shifted by one; only E3 was rated.
    final now = {e(1, 1): 50, e(1, 2): 11, e(1, 3): 12, e(1, 4): 13};
    final result = propose([rated(e(1, 3), 13)], now);
    expect(result, hasLength(1));
    expect(result.single.moves, [RenumberMove(e(1, 3), e(1, 4))]);
    expect(result.single.conflicts, isEmpty);
  });

  test('a shift of several rated episodes is one question', () {
    final now = {e(1, 1): 50, e(1, 2): 11, e(1, 3): 12, e(1, 4): 13};
    final result = propose([rated(e(1, 1), 11), rated(e(1, 2), 12)], now);
    expect(result, hasLength(1));
    expect(result.single.moves, [
      RenumberMove(e(1, 1), e(1, 2)),
      RenumberMove(e(1, 2), e(1, 3)),
    ]);
    // E2 is rated, but its rating moves on: no conflict.
    expect(result.single.conflicts, isEmpty);
  });

  test('a swap is one question without a conflict', () {
    final now = {e(1, 1): 12, e(1, 2): 11};
    final result = propose([rated(e(1, 1), 11), rated(e(1, 2), 12)], now);
    expect(result, hasLength(1));
    expect(result.single.moves, [
      RenumberMove(e(1, 1), e(1, 2)),
      RenumberMove(e(1, 2), e(1, 1)),
    ]);
    expect(result.single.conflicts, isEmpty);
  });

  test('a move across seasons is found in the season it went to', () {
    // S1E4 became S2E1; the user opened season 2.
    final season2 = {e(2, 1): 14, e(2, 2): 21};
    final result = propose([rated(e(1, 4), 14)], season2);
    expect(result.single.moves, [RenumberMove(e(1, 4), e(2, 1))]);
  });

  test('an episode no longer under any loaded number stays', () {
    // Vanished from TMDB, or moved to a season that wasn't opened.
    final now = {e(1, 1): 11, e(1, 2): 12, e(1, 3): 99};
    expect(propose([rated(e(1, 3), 13)], now), isEmpty);
  });

  test('a double episode merged into one: which score stays', () {
    // E1 (id 11) and E2 (id 12) became one E1 that kept E2's id.
    final now = {e(1, 1): 12, e(1, 2): 13};
    final result = propose([rated(e(1, 1), 11), rated(e(1, 2), 12)], now);
    expect(result.single.moves, [RenumberMove(e(1, 2), e(1, 1))]);
    // E1's own id 11 is gone, so its rating doesn't move away.
    expect(result.single.conflicts, {e(1, 1)});
  });

  test('a target rated after the renumbering is a conflict', () {
    // E3 moved to E4, and E4 was rated meanwhile (with id 13, TMDB's now).
    final now = {e(1, 3): 50, e(1, 4): 13};
    final result = propose([rated(e(1, 3), 13), rated(e(1, 4), 13)], now);
    expect(result.single.moves, [RenumberMove(e(1, 3), e(1, 4))]);
    expect(result.single.conflicts, {e(1, 4)});
  });

  test('a conflict at the end of a shift belongs to the same question', () {
    final now = {e(1, 1): 50, e(1, 2): 11, e(1, 3): 12};
    final result = propose([
      rated(e(1, 1), 11),
      rated(e(1, 2), 12),
      rated(e(1, 3), 12),
    ], now);
    expect(result.single.moves, [
      RenumberMove(e(1, 1), e(1, 2)),
      RenumberMove(e(1, 2), e(1, 3)),
    ]);
    expect(result.single.conflicts, {e(1, 3)});
    expect(result.single.moveTo(e(1, 3)), RenumberMove(e(1, 2), e(1, 3)));
  });

  test('two ratings claiming one target: the first moves now', () {
    // Possible after a merge from another device saved the same id twice.
    final now = {e(1, 1): 50, e(1, 2): 11};
    final result = propose([rated(e(1, 3), 11), rated(e(1, 1), 11)], now);
    expect(result.single.moves, [RenumberMove(e(1, 1), e(1, 2))]);
  });

  test('independent moves are separate questions, in number order', () {
    final now = {e(1, 1): 12, e(1, 2): 50, e(1, 3): 14, e(1, 4): 51};
    final result = propose([rated(e(1, 4), 14), rated(e(1, 2), 12)], now);
    expect(
      [for (final r in result) r.moves],
      [
        [RenumberMove(e(1, 2), e(1, 1))],
        [RenumberMove(e(1, 4), e(1, 3))],
      ],
    );
    expect(result.first.touches(e(1, 1)), isTrue);
    expect(result.first.touches(e(1, 3)), isFalse);
  });

  test('seasons move by their own id the same way', () {
    // Specials appeared as season 0 and the seasons kept their numbers, but
    // TMDB split season 1 in two: old S2 (id 202) is now S3.
    final now = {s(0): 300, s(1): 201, s(2): 250, s(3): 202};
    final result = propose([rated(s(1), 201), rated(s(2), 202)], now);
    expect(result.single.moves, [RenumberMove(s(2), s(3))]);
    expect(result.single.conflicts, isEmpty);
  });

  test('an id is matched only within the same kind and series', () {
    // A season id equal to an episode id, and an episode of another series.
    expect(propose([rated(s(1), 12)], season1), isEmpty);
    expect(
      propose([rated(const WorkKey.episode(7, 1, 1), 12)], season1),
      isEmpty,
    );
  });
}
