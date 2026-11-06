import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/l10n/app_localizations.dart';
import 'package:framebook/shared/format.dart';

void main() {
  for (final locale in ['en', 'ru']) {
    testWidgets(
      'calendar formatting rejects normalized impossible dates: $locale',
      (tester) async {
        List<String?> dates = [];
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                dates = [
                  for (final raw in [
                    null,
                    '2023-02-29',
                    '2024-13-01',
                    '2024-01-00',
                    'not-a-date',
                    '2024-02-29',
                  ])
                    context.formatDate(raw),
                ];
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(dates.take(5), [null, null, null, null, null]);
        expect(dates.last, contains('2024'));
        expect(dates.last, contains('29'));
      },
    );
  }
}
