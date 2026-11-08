import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';

void main() {
  final today = DateTime(2026, 11, 8, 23, 59);
  test('release eligibility uses valid calendar dates and includes today', () {
    for (final pending in [false, true]) {
      expect(
        releaseState('2026-11-08', today: today, awaitingRelease: pending),
        ReleaseState.released,
      );
      expect(
        releaseState('2026-11-07', today: today, awaitingRelease: pending),
        ReleaseState.released,
      );
      expect(
        releaseState('2026-11-09', today: today, awaitingRelease: pending),
        ReleaseState.upcoming,
      );
      for (final date in [null, '', '2026-02-30', 'unknown']) {
        expect(
          releaseState(date, today: today, awaitingRelease: pending),
          pending ? ReleaseState.upcoming : ReleaseState.unknown,
        );
      }
    }
  });

  test('TV production statuses preserve evidence of an unreleased series', () {
    for (final status in ['Planned', 'Pilot', 'In Production']) {
      final tv = TvDetails.fromJson(Json({'id': 1, 'status': status}));
      expect(tv.status.awaitingRelease, isTrue);
      expect(tv.status, isNot(TvStatus.running));
      expect(
        releaseState(
          tv.firstAirDate,
          today: today,
          awaitingRelease: tv.status.awaitingRelease,
        ),
        ReleaseState.upcoming,
      );
    }
    expect(TvStatus.parse('Returning Series'), TvStatus.running);
    expect(TvStatus.parse('Ended'), TvStatus.ended);
    expect(TvStatus.parse('Canceled'), TvStatus.canceled);
    expect(TvStatus.parse('Unexpected'), TvStatus.unknown);
  });

  test(
    'movie production status distinguishes unknown from pending release',
    () {
      for (final status in [
        'Rumored',
        'Planned',
        'In Production',
        'Post Production',
      ]) {
        expect(
          MovieDetails.fromJson(
            Json({'id': 1, 'status': status}),
          ).awaitingRelease,
          isTrue,
        );
      }
      expect(
        MovieDetails.fromJson(
          const Json({'id': 1, 'status': 'Released'}),
        ).awaitingRelease,
        isFalse,
      );
    },
  );
}
