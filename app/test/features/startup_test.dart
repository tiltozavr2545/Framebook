import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/startup.dart';

void main() {
  for (final failure in [
    StateError('database private detail'),
    PlatformException(code: 'secure_storage', message: 'private key detail'),
  ]) {
    testWidgets('initialization can retry after ${failure.runtimeType}', (
      tester,
    ) async {
      var attempts = 0;
      await tester.pumpWidget(
        StartupApp(
          load: () async {
            if (++attempts == 1) {
              Error.throwWithStackTrace(failure, StackTrace.current);
            }
            return const MaterialApp(home: Text('ready'));
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('could not open its local data'),
        findsOneWidget,
      );
      expect(find.textContaining('private'), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
    });
  }
}
