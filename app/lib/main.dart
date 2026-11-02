import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/startup.dart';
import 'app/preferences.dart';
import 'data/api_keys.dart';
import 'data/db/database.dart';
import 'data/db/database_provider.dart';
import 'data/library/library.dart';
import 'data/response_cache.dart';
import 'data/sources/tmdb/tmdb_client.dart';
import 'data/sync/sync_controller.dart';
import 'data/sync/sync_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(StartupApp(load: initializeApp));
}

Future<Widget> initializeApp() async {
  // The application router receives preferences and keys together. StartupApp
  // owns the loading/retry UI until this initialization succeeds.
  final db = AppDatabase.open();
  try {
    // device_id is created on first launch and never changes (docs/sync.md).
    final deviceId = await db.deviceId();
    await SyncStore(
      db,
    ).preparePartIdentities(DateTime.now().toUtc().millisecondsSinceEpoch);
    final prefs = await SharedPreferences.getInstance();
    final keyStore = ApiKeyStore(SecureKeyStorage());
    final keys = await keyStore.load();
    final package = await PackageInfo.fromPlatform();
    final cache = FileResponseCache(
      Directory(p.join((await getApplicationCacheDirectory()).path, 'http')),
    );

    // Cleanup can wait until after the first frame.
    // Evictable cleanup must not turn a successful startup into an uncaught error.
    unawaited(db.pruneBudget(DateTime.now()).catchError((Object _) {}));
    unawaited(cache.prune(TmdbTtl.longest).catchError((Object _) {}));

    return ProviderScope(
      // No automatic retry: a card error is offline or a TMDB refusal, and
      // retrying those on a timer is pointless. The error screen has a retry
      // button.
      retry: (_, _) => null,
      overrides: [
        databaseProvider.overrideWithValue(db),
        deviceIdProvider.overrideWithValue(deviceId),
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiKeyStoreProvider.overrideWithValue(keyStore),
        initialApiKeysProvider.overrideWithValue(keys),
        responseCacheProvider.overrideWithValue(cache),
        // Written into the sync file (docs/sync.md, "File format").
        appVersionProvider.overrideWithValue(
          '${package.version}+${package.buildNumber}',
        ),
      ],
      child: const FramebookApp(),
    );
  } catch (_) {
    try {
      await db.close();
    } catch (_) {
      /* Preserve the initialization error. */
    }
    rethrow;
  }
}
