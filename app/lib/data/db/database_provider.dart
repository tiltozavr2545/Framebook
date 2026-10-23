import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Открывается в `main()` до `runApp` (там же создаётся `device_id`) и
/// подставляется через override; в тестах — БД в памяти.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);
