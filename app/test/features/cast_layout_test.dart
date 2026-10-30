import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/features/title/cast_section.dart';
import 'package:framebook/l10n/app_localizations.dart';

void main() {
  for (final scale in [1.0, 1.3, 2.0, 3.0]) {
    testWidgets('cast name and role fit at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(640, 1560);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      const role = 'An exceptionally long character name and role';
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: FramebookTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => ListView(
                  children: castSection(
                    context,
                    const Credits(
                      cast: [
                        CastMember(
                          personId: 1,
                          name: 'A Very Long Performer Name',
                          character: role,
                          profilePath: null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final roleText = tester.widget<Text>(find.text(role));
      expect(roleText.maxLines, 2);
      expect(roleText.overflow, TextOverflow.ellipsis);
      final roleBounds = tester.getRect(find.text(role));
      final stripBounds = tester.getRect(find.byType(Scrollable).last);
      expect(roleBounds.bottom, lessThanOrEqualTo(stripBounds.bottom));
    });
  }
}
