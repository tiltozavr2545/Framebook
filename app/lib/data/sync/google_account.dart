import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'drive_remote.dart';
import 'sync_engine.dart';

/// The OAuth "Web application" client id of the Framebook Google Cloud
/// project. On Android, Credential Manager signs in with it (google_sign_in
/// 7 calls it `serverClientId`); the Android clients for each signing key
/// live in the same project (docs/operations.md, "Google Cloud"). A client
/// id is not a secret, so it lives here rather than in a build variable.
const googleServerClientId =
    '682712190545-e1qbllq2u8htfgugv8h0a20on0ab1ffo.apps.googleusercontent.com';

/// The only scope: the app's own hidden folder, nothing else on Drive.
const driveScopes = [drive.DriveApi.driveAppdataScope];

/// Why signing in didn't happen.
enum SignInFailure {
  /// The user closed the dialog.
  canceled,

  /// The OAuth clients don't match this build (ApiException: 10 and the
  /// like) — a setup problem, not the user's.
  misconfigured,

  failed,
}

final class SignInException implements Exception {
  const SignInException(this.failure, [this.detail]);

  final SignInFailure failure;
  final String? detail;

  @override
  String toString() =>
      'SignInException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// Drive access for one sync: the remote, and a way to drop its token when
/// Drive says it has expired.
typedef DriveAccess = ({SyncRemote remote, Future<void> Function() expire});

/// The Google account sync goes through. An interface so that widget tests
/// can run without Google.
abstract interface class GoogleAccount {
  /// Whether this build can sign in at all.
  bool get configured;

  /// The account signed in earlier, without any UI; `null` if none.
  Future<String?> restore();

  /// Signs in and asks for Drive access, with Google's own dialogs. Returns
  /// the email. Throws [SignInException].
  Future<String> signIn();

  /// Drive access without UI. Throws [SyncException] with
  /// [SyncFailure.unauthorized] when the user has to sign in again.
  Future<DriveAccess> drive();

  Future<void> signOut();
}

final class GoogleSignInAccountService implements GoogleAccount {
  GoogleSignInAccountService({this.serverClientId = googleServerClientId});

  final String serverClientId;
  Future<void>? _initialized;
  GoogleSignInAccount? _account;

  @override
  bool get configured => serverClientId.isNotEmpty;

  Future<void> _init() => _initialized ??= GoogleSignIn.instance.initialize(
    serverClientId: serverClientId,
  );

  @override
  Future<String?> restore() async {
    if (!configured) return null;
    await _init();
    try {
      _account =
          await GoogleSignIn.instance.attemptLightweightAuthentication() ??
          _account;
    } on GoogleSignInException {
      return null;
    }
    return _account?.email;
  }

  @override
  Future<String> signIn() async {
    if (!configured) throw const SignInException(SignInFailure.misconfigured);
    await _init();
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: driveScopes,
      );
      await account.authorizationClient.authorizeScopes(driveScopes);
      _account = account;
      return account.email;
    } on GoogleSignInException catch (e) {
      throw SignInException(switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted => SignInFailure.canceled,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          SignInFailure.misconfigured,
        _ => SignInFailure.failed,
      }, e.description);
    }
  }

  @override
  Future<DriveAccess> drive() async {
    final account = _account ?? (await restore() == null ? null : _account);
    if (account == null) {
      throw const SyncException(SyncFailure.unauthorized, 'not signed in');
    }
    final GoogleSignInClientAuthorization? authorization;
    try {
      authorization = await account.authorizationClient.authorizationForScopes(
        driveScopes,
      );
    } on GoogleSignInException catch (e) {
      throw SyncException(SyncFailure.unauthorized, e.description);
    }
    if (authorization == null) {
      throw const SyncException(SyncFailure.unauthorized, 'no Drive access');
    }
    return (
      remote: DriveRemote(authorization.authClient(scopes: driveScopes)),
      expire: () => account.authorizationClient.clearAuthorizationToken(
        accessToken: authorization!.accessToken,
      ),
    );
  }

  @override
  Future<void> signOut() async {
    if (!configured) return;
    await _init();
    _account = null;
    await GoogleSignIn.instance.signOut();
  }
}

final googleAccountProvider = Provider<GoogleAccount>(
  (ref) => GoogleSignInAccountService(),
);
