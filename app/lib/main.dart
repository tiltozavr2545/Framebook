import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/preferences.dart';
import 'data/api_keys.dart';
import 'data/db/database.dart';
import 'data/db/database_provider.dart';
import 'data/response_cache.dart';
import 'data/sources/tmdb/tmdb_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Everything the first frame needs is read before runApp: theme and language
  // so as not to flash the wrong ones, keys so the router knows right away
  // whether to show onboarding.
  final db = AppDatabase.open();
  // device_id is created on first launch and never changes (docs/sync.md).
  await db.deviceId();
  final prefs = await SharedPreferences.getInstance();
  final keyStore = ApiKeyStore(SecureKeyStorage());
  final keys = await keyStore.load();
  final cache = FileResponseCache(
    Directory(p.join((await getApplicationCacheDirectory()).path, 'http')),
  );

  // Cleanup can wait until after the first frame.
  unawaited(db.pruneBudget(DateTime.now()));
  unawaited(cache.prune(TmdbTtl.longest));

  runApp(
    ProviderScope(
      // No automatic retry: a card error is offline or a TMDB refusal, and
      // retrying those on a timer is pointless. The error screen has a retry
      // button.
      retry: (_, _) => null,
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiKeyStoreProvider.overrideWithValue(keyStore),
        initialApiKeysProvider.overrideWithValue(keys),
        responseCacheProvider.overrideWithValue(cache),
      ],
      child: const FramebookApp(),
    ),
  );
}
