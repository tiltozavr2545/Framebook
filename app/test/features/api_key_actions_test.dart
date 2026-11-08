import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/api_keys.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/key_validator.dart';
import 'package:framebook/features/settings/api_keys_form.dart';
import 'package:framebook/l10n/app_localizations.dart';

import '../support/memory_key_storage.dart';

class _PendingProbe implements HttpClientAdapter {
  final release = Completer<ResponseBody>();
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    calls++;
    return release.future;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets(
    'repeated keyboard submissions spend only one key-check request',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final storage = MemoryKeyStorage();
      final store = ApiKeyStore(storage);
      final http = _PendingProbe();
      final dio = createDio()..httpClientAdapter = http;
      addTearDown(() async {
        if (!http.release.isCompleted) {
          http.release.complete(ResponseBody.fromString('{"id":301}', 200));
        }
        dio.close();
        await db.close();
      });
      final container = ProviderContainer(
        overrides: [
          initialApiKeysProvider.overrideWithValue(ApiKeys.empty),
          apiKeyStoreProvider.overrideWithValue(store),
          keyValidatorProvider.overrideWithValue(KeyValidator(dio, db)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FramebookTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: ApiKeysForm()),
            ),
          ),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField).at(1));
      field.controller!.text = 'fixture-key';
      field.onSubmitted!('fixture-key');
      field.onSubmitted!('fixture-key');
      await tester.pumpAndSettle();
      expect(http.calls, 1);
      expect(
        await db.budgetUsed(
          ApiSource.poiskkino,
          AppDatabase.budgetDay(DateTime.now()),
        ),
        1,
      );
      http.release.complete(ResponseBody.fromString('{"id":301}', 200));
      await tester.pumpAndSettle();
      expect(
        container.read(apiKeysProvider)[ApiSource.poiskkino]?.value,
        'fixture-key',
      );
      expect((await store.load())[ApiSource.poiskkino]?.verified, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
