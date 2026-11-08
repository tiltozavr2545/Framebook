import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';

void main() {
  testWidgets('Russian glyphs keep their shapes in either interface language', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final (family, files) in [
        (
          Fonts.text,
          [
            for (final w in [400, 500, 600, 700]) 'SofiaSans-$w',
          ],
        ),
        (
          Fonts.display,
          [
            for (final w in [500, 700, 800]) 'SofiaSansExtraCondensed-$w',
          ],
        ),
      ]) {
        final loader = FontLoader(family);
        for (final file in files) {
          loader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
        }
        await loader.load();
      }

      Future<List<int>> render(TextStyle style, String language) async {
        final painter = TextPainter(
          text: TextSpan(
            text: 'Водитель Дмитрий: тдпий Яя — Film 1999 8.5',
            style: style,
          ),
          textDirection: TextDirection.ltr,
          locale: Locale(language),
        )..layout(maxWidth: 720);
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), Offset.zero);
        final picture = recorder.endRecording();
        final image = await picture.toImage(720, painter.height.ceil());
        final bytes = await image.toByteData();
        painter.dispose();
        picture.dispose();
        image.dispose();
        return bytes!.buffer.asUint8List();
      }

      final theme = FramebookTheme.light.textTheme;
      for (final style in [
        theme.bodyMedium!,
        theme.labelMedium!,
        theme.titleLarge!,
        theme.headlineSmall!,
        theme.displayLarge!,
      ]) {
        expect(
          listEquals(await render(style, 'en'), await render(style, 'ru')),
          isTrue,
          reason: '${style.fontFamily} ${style.fontWeight}',
        );
      }
    });
  });
}
