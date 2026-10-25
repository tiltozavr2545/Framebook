import 'package:framebook/data/sync/google_account.dart';
import 'package:framebook/data/sync/sync_engine.dart';

import 'memory_remote.dart';

/// A Google account over a [MemoryRemote]: sign-in always succeeds.
class FakeGoogleAccount implements GoogleAccount {
  FakeGoogleAccount(
    this.remote, {
    this.configured = true,
    this.email = 'me@example.com',
  });

  final MemoryRemote remote;
  final String email;
  bool signedIn = false;

  @override
  final bool configured;

  @override
  Future<String?> restore() async => signedIn ? email : null;

  @override
  Future<String> signIn() async {
    signedIn = true;
    return email;
  }

  @override
  Future<DriveAccess> drive() async {
    if (!signedIn) throw const SyncException(SyncFailure.unauthorized);
    return (remote: remote as SyncRemote, expire: () async {});
  }

  @override
  Future<void> signOut() async => signedIn = false;
}
