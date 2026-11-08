import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/timestamps.dart';

void main() {
  test('user versions advance through clock rollback', () {
    var previous = 100;
    for (final now in [101, 0, -1, 1000, 2]) {
      final next = nextTimestampMillis(now, previous);
      expect(next, greaterThan(previous));
      expect(next, greaterThanOrEqualTo(now));
      expect(validTimestampMillis(next), isTrue);
      previous = next;
    }
  });

  test('the last supported version never wraps on another edit', () {
    final last = nextTimestampMillis(0, maxTimestampMillis - 1);
    expect(last, maxTimestampMillis);
    expect(
      () => nextTimestampMillis(0, last),
      throwsA(isA<TimestampRangeException>()),
    );
  });

  test('out-of-range clocks and stored versions cannot enter arithmetic', () {
    for (final bad in [
      maxTimestampMillis + 1,
      -maxTimestampMillis - 1,
      0x7fffffffffffffff,
      -0x7fffffffffffffff - 1,
    ]) {
      expect(validTimestampMillis(bad), isFalse);
      expect(
        () => nextTimestampMillis(bad, 0),
        throwsA(isA<TimestampRangeException>()),
      );
      expect(
        () => nextTimestampMillis(0, bad),
        throwsA(isA<TimestampRangeException>()),
      );
    }
  });
}
