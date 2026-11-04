import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as platform;
import 'package:googleapis/drive/v3.dart' as drive;

import '../../app/preferences.dart';
import 'drive_remote.dart';
import 'sync_engine.dart';

/// The OAuth "Web application" client id of the Framebook Google Cloud
/// project. On Android, Credential Manager signs in with it (google_sign_in
/// 7 calls it `serverClientId`); the Android clients for each signing key
/// live in the same project (docs/operations.md, "Google Cloud"). A client
/// id is not a secret, so it lives here rather than in a build variable.
const googleServerClientId =
    '682712190545-e1qbllq2u8htfgugv8h0a20on0ab1ffo.apps.googleusercontent.com';

/// The account explicitly selected for synchronization.
const syncAccountPreferenceKey = 'sync_account';

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
typedef DriveAccess = ({
  SyncRemote remote,
  Future<void> Function() expire,
  void Function() close,
});

/// The Google account sync goes through. An interface so that widget tests
/// can run without Google.
abstract interface class GoogleAccount {
  /// Whether this build can sign in at all.
  bool get configured;

  /// The previously selected account, without UI; Drive access may need renewal.
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
  GoogleSignInAccountService({
    required this.readStoredAccount,
    this.serverClientId = googleServerClientId,
  });

  final String serverClientId;
  final String? Function() readStoredAccount;
  Future<void>? _initialized;
  String? _accountEmail;
  int _epoch = 0;

  @override
  bool get configured => serverClientId.isNotEmpty;

  Future<void> _init() => _initialized ??= GoogleSignIn.instance.initialize(
    serverClientId: serverClientId,
  );

  @override
  Future<String?> restore() async {
    if (!configured) return null;
    // This is the user's previous selection, not proof of current Drive access.
    // Credential Manager's lightweight authentication can show UI on Android.
    return _accountEmail ??= readStoredAccount();
  }

  @override
  Future<String> signIn() async {
    if (!configured) throw const SignInException(SignInFailure.misconfigured);
    final epoch = ++_epoch;
    await _init();
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: driveScopes,
      );
      await account.authorizationClient.authorizeScopes(driveScopes);
      if (epoch != _epoch) {
        throw const SignInException(SignInFailure.canceled);
      }
      _accountEmail = account.email;
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
    final email = await restore();
    if (email == null) {
      throw const SyncException(SyncFailure.unauthorized, 'not signed in');
    }
    final epoch = _epoch;
    final GoogleSignInClientAuthorization authorization;
    try {
      await _init();
      // The public account-less client cannot bind an explicit email. Use the
      // plugin's platform API so Android calls AuthorizationRequest.setAccount
      // and never silently falls back to a different account on the device.
      final tokens = await platform.GoogleSignInPlatform.instance
          .clientAuthorizationTokensForScopes(
            platform.ClientAuthorizationTokensForScopesParameters(
              request: platform.AuthorizationRequestDetails(
                scopes: driveScopes,
                userId: null,
                email: email,
                promptIfUnauthorized: false,
              ),
            ),
          );
      if (epoch != _epoch || email != _accountEmail) {
        throw const SyncException(SyncFailure.unauthorized, 'account changed');
      }
      if (tokens == null) {
        throw const SyncException(SyncFailure.unauthorized, 'no Drive access');
      }
      authorization = GoogleSignInClientAuthorization(
        accessToken: tokens.accessToken,
      );
    } on GoogleSignInException catch (e) {
      // Unknown SDK failures can be transient (for example a network outage),
      // and do not prove that permission was revoked.
      throw SyncException(
        e.code == GoogleSignInExceptionCode.unknownError
            ? SyncFailure.failed
            : SyncFailure.unauthorized,
        e.description,
      );
    }
    final client = authorization.authClient(scopes: driveScopes);
    return (
      remote: DriveRemote(client),
      close: client.close,
      expire: () => GoogleSignIn.instance.authorizationClient
          .clearAuthorizationToken(accessToken: authorization.accessToken),
    );
  }

  @override
  Future<void> signOut() async {
    if (!configured) return;
    _epoch++;
    _accountEmail = null;
    await _init();
    await GoogleSignIn.instance.signOut();
  }
}

final googleAccountProvider = Provider<GoogleAccount>(
  (ref) => GoogleSignInAccountService(
    readStoredAccount: () =>
        ref.read(sharedPreferencesProvider).getString(syncAccountPreferenceKey),
  ),
);
