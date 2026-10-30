import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/sync/sync_controller.dart';
import 'package:framebook/data/sync/secrets_controller.dart';
import 'package:framebook/features/settings/sync_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';

class _SecretsOff extends SecretsController {
  @override
  SecretsStatus build() => const SecretsStatus();
}

class _PausedSync extends SyncController {
  bool? answer;
  String? reviewed;

  void changeConflict() {
    state = state.copyWith(stale: () => 4, staleFingerprint: () => 'new');
  }

  @override
  SyncStatus build() => const SyncStatus(
    configured: true,
    account: 'test@example.com',
    stale: 3,
    staleFingerprint: 'reviewed',
  );

  @override
  Future<void> resolveStale({
    required bool keep,
    required String fingerprint,
  }) async {
    reviewed = fingerprint;
    answer = keep;
    state = state.copyWith(stale: () => null);
  }
}

void main() {
  for (final keep in [true, false]) {
    testWidgets('paused sync asks before ${keep ? 'keeping' : 'discarding'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final controller = _PausedSync();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncControllerProvider.overrideWith(() => controller),
            secretsControllerProvider.overrideWith(_SecretsOff.new),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: SyncScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sync is paused until you answer a question'), findsOne);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('newer deletion in Google Drive: 3.'),
        findsOne,
      );
      expect(find.textContaining('Keep restores these entries'), findsOne);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.answer, isNull);
      expect(find.text('Review'), findsOne);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(keep ? 'Keep' : 'Discard'));
      await tester.pumpAndSettle();
      expect(controller.answer, keep);
      expect(controller.reviewed, 'reviewed');
      expect(find.text('Review'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('an open dialog returns the fingerprint it showed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final controller = _PausedSync();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncControllerProvider.overrideWith(() => controller),
          secretsControllerProvider.overrideWith(_SecretsOff.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: SyncScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    controller.changeConflict();
    await tester.pump();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(controller.reviewed, 'reviewed');
  });
}
