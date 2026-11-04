import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/shared/poster_tint.dart';
import 'package:framebook/shared/score_color.dart';

void main() {
  test('score bands respect boundaries and have readable theme contrast', () {
    for (final theme in [FramebookTheme.light, FramebookTheme.dark]) {
      final brightness = theme.brightness;
      expect(scoreColorFor(brightness, 3.5), scoreColorFor(brightness, 1));
      expect(scoreColorFor(brightness, 4), scoreColorFor(brightness, 6.5));
      expect(scoreColorFor(brightness, 6.6), scoreColorFor(brightness, 10));
      expect(
        scoreColorFor(brightness, 3.999),
        isNot(scoreColorFor(brightness, 4)),
      );
      expect(
        scoreColorFor(brightness, 6.5),
        isNot(scoreColorFor(brightness, 6.501)),
      );
      for (final score in [1.0, 5.0, 7.0]) {
        final foreground = scoreColorFor(brightness, score).computeLuminance();
        final background = theme.colorScheme.surface.computeLuminance();
        final high = foreground > background ? foreground : background;
        final low = foreground < background ? foreground : background;
        expect((high + 0.05) / (low + 0.05), greaterThanOrEqualTo(4.5));
      }
    }
  });

  test('poster tint uses the most common colour and ignores transparency', () {
    expect(
      dominantPosterColor(
        Uint8List.fromList([
          200,
          30,
          20,
          255,
          202,
          30,
          22,
          255,
          0,
          0,
          255,
          255,
          0,
          255,
          0,
          0,
          0,
          255,
          0,
          0,
        ]),
      ),
      const Color.fromARGB(255, 201, 30, 21),
    );
    expect(dominantPosterColor(Uint8List(16)), isNull);
    expect(dominantPosterColor(Uint8List(0)), isNull);
  });

  test('dark poster borders do not hide a characteristic artwork colour', () {
    final pixels = Uint8List.fromList([
      for (var i = 0; i < 100; i++) ...[5, 5, 5, 255],
      for (var i = 0; i < 10; i++) ...[20, 140, 180, 255],
    ]);
    expect(
      dominantPosterColor(pixels),
      const Color.fromARGB(255, 20, 140, 180),
    );
  });
}
