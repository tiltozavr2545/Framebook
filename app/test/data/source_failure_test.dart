import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/source_failure.dart';

void main() {
  test(
    'integer fields reject fractional, nonfinite and overflowing values',
    () {
      for (final value in [
        1.5,
        double.nan,
        double.infinity,
        -double.infinity,
        1e100,
        '3',
        null,
      ]) {
        expect(Json({'id': value}).integer('id'), isNull, reason: '$value');
      }
      expect(const Json({'id': 3}).integer('id'), 3);
      expect(const Json({'id': 3.0}).integer('id'), 3);
      expect(
        const Json({'id': 9223372036854775807}).integer('id'),
        9223372036854775807,
      );
    },
  );

  test(
    'numeric fields reject nonfinite values including JSON exponent overflow',
    () {
      for (final value in [double.nan, double.infinity, -double.infinity]) {
        expect(Json({'rating': value}).number('rating'), isNull);
      }
      final json = tryJson('{"rating":1e999,"id":1e999}')!;
      expect(json.number('rating'), isNull);
      expect(json.integer('id'), isNull);
      expect(const Json({'rating': 8.5}).number('rating'), 8.5);
    },
  );
}
