import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/update_version.dart';

void main() {
  test('compares numeric versions and ignores build numbers', () {
    expect(
      UpdateVersion.parse(
        'v0.10.0',
      )!.compareTo(UpdateVersion.parse('0.9.9+9')!),
      greaterThan(0),
    );
    expect(
      UpdateVersion.parse('0.7.0+9')!.compareTo(UpdateVersion.parse('v0.7.0')!),
      0,
    );
  });
  test('rejects prereleases and invalid versions', () {
    for (final value in ['v1.0.0-rc.1', 'v01.0.0', '1.0', 'latest']) {
      expect(UpdateVersion.parse(value), isNull);
    }
  });
}
