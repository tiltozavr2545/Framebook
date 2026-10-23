import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/preferences.dart';
import 'data/api_keys.dart';
import 'data/db/database.dart';
import 'data/db/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Всё, что нужно первому кадру, читается до runApp: тема и язык — чтобы не
  // мигнуть чужими, ключи — чтобы роутер сразу знал, показывать ли
  // онбординг.
  final db = AppDatabase.open();
  // device_id создаётся на первом запуске и больше не меняется (docs/sync.md).
  await db.deviceId();
  final prefs = await SharedPreferences.getInstance();
  final keyStore = ApiKeyStore(SecureKeyStorage());
  final keys = await keyStore.load();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiKeyStoreProvider.overrideWithValue(keyStore),
        initialApiKeysProvider.overrideWithValue(keys),
      ],
      child: const FramebookApp(),
    ),
  );
}
