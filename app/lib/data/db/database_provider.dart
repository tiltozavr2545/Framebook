import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Opened in `main()` before `runApp` (where `device_id` is created too) and
/// provided through an override; tests use an in-memory database.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);
