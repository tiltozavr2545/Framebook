import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/sync/secrets_controller.dart';
import 'package:framebook/data/sync/sync_controller.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/features/settings/sync_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';

class _SecretsOff extends SecretsController {
  @override
  SecretsStatus build() => const SecretsStatus();
}

class _FileSync extends SyncController {
  List<int>? bytes;
  final replacements = <bool>[];
  bool failImport = false;
  SyncFileException? previewFailure;

  @override
  SyncStatus build() => const SyncStatus(configured: false);

  @override
  Future<ImportPreview> previewImport(List<int> bytes) async {
    this.bytes = bytes;
    if (previewFailure case final error?) throw error;
    return (
      file: const SyncState(),
      device: 2,
      inFile: 3,
      merged: 4,
      stale: 0,
      fingerprint: 'preview',
    );
  }

  @override
  Future<ImportPreview?> import(
    SyncState file, {
    required bool replace,
    bool keepStale = true,
    String? reviewedFingerprint,
  }) async {
    replacements.add(replace);
    if (failImport) throw StateError('Storage unavailable');
    return null;
  }
}

Future<void> _pumpFiles(
  WidgetTester tester,
  _FileSync controller,
  Future<FilePickerResult?> Function() pick,
) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        syncControllerProvider.overrideWith(() => controller),
        syncFilePickerProvider.overrideWithValue(pick),
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
  await tester.ensureVisible(find.text('Import from a file'));
}

FilePickerResult _picked({int size = 3, bool readable = true}) =>
    FilePickerResult([
      PlatformFile(
        name: 'export.json.gz',
        size: size,
        readStream: readable ? Stream.value([1, 2, 3]) : null,
      ),
    ]);

void main() {
  for (final scenario in [
    'picker_cancel',
    'picker_failure',
    'too_large',
    'no_stream',
    'broken',
    'too_new',
  ]) {
    testWidgets('file selection failure UI: $scenario', (tester) async {
      final controller = _FileSync()
        ..previewFailure = switch (scenario) {
          'broken' => const SyncFileBroken('Invalid data'),
          'too_new' => const SyncFileTooNew(99),
          _ => null,
        };
      await _pumpFiles(
        tester,
        controller,
        () async => switch (scenario) {
          'picker_cancel' => null,
          'picker_failure' => throw StateError('Picker unavailable'),
          'too_large' => _picked(size: SyncFile.maxCompressedBytes + 1),
          'no_stream' => _picked(readable: false),
          _ => _picked(),
        },
      );
      try {
        await tester.tap(find.text('Import from a file'));
        await tester.pumpAndSettle();
        expect(controller.replacements, isEmpty);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Imported'), findsNothing);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(SyncScreen)),
        );
        final message = switch (scenario) {
          'picker_cancel' => null,
          'too_large' => l10n.syncErrorTooLarge,
          'broken' || 'no_stream' => l10n.importBroken,
          'too_new' => l10n.importTooNew,
          _ => l10n.fileOperationFailed,
        };
        if (message != null) expect(find.text(message), findsOneWidget);
        if (scenario == 'too_large' ||
            scenario.startsWith('picker') ||
            scenario == 'no_stream') {
          expect(controller.bytes, isNull);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
    });
  }

  for (final action in [
    'cancel',
    'merge',
    'replace_cancel',
    'replace',
    'merge_failure',
  ]) {
    testWidgets('file import UI: $action', (tester) async {
      final controller = _FileSync()..failImport = action == 'merge_failure';
      await _pumpFiles(tester, controller, () async => _picked());
      try {
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Import from a file'));
        await tester.tap(find.text('Import from a file'));
        await tester.pumpAndSettle();
        expect(controller.bytes, [1, 2, 3]);
        expect(find.textContaining('After merging: 4.'), findsOneWidget);
        if (action == 'cancel') {
          await tester.tap(find.text('Cancel'));
        } else if (action.startsWith('replace')) {
          await tester.tap(find.text('Replace everything'));
          await tester.pumpAndSettle();
          expect(
            find.text('Replace everything with the file?'),
            findsOneWidget,
          );
          await tester.tap(
            find.text(
              action == 'replace_cancel' ? 'Cancel' : 'Replace everything',
            ),
          );
        } else {
          await tester.tap(find.text('Merge'));
        }
        await tester.pumpAndSettle();
        final cancelled = action == 'cancel' || action == 'replace_cancel';
        expect(
          controller.replacements,
          cancelled ? isEmpty : [action == 'replace'],
        );
        expect(
          find.text('Imported'),
          cancelled || controller.failImport ? findsNothing : findsOneWidget,
        );
        if (controller.failImport) {
          expect(
            find.text('Could not read or save the file. Try again.'),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
    });
  }
}
