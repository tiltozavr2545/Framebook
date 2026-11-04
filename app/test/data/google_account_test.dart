import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/sync/google_account.dart';
import 'package:framebook/data/sync/sync_engine.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

class _GooglePlatform extends GoogleSignInPlatform {
  final requests = <AuthorizationRequestDetails>[];
  final cleared = <String>[];
  int lightweightCalls = 0;
  int interactiveCalls = 0;
  String? token = 'drive-token';
  GoogleSignInException? failure;
  Completer<ClientAuthorizationTokenData?>? pending;

  @override
  Future<void> init(InitParameters params) async {}

  @override
  Future<AuthenticationResults?> attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) async {
    lightweightCalls++;
    throw StateError('Startup must not launch Credential Manager');
  }

  @override
  bool supportsAuthenticate() => true;

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    interactiveCalls++;
    return const AuthenticationResults(
      user: GoogleSignInUserData(
        email: 'selected@example.com',
        id: 'selected-id',
      ),
      authenticationTokens: AuthenticationTokenData(idToken: 'id-token'),
    );
  }

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async {
    requests.add(params.request);
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    return token == null
        ? null
        : ClientAuthorizationTokenData(accessToken: token!);
  }

  @override
  Future<void> clearAuthorizationToken(
    ClearAuthorizationTokenParams params,
  ) async {
    cleared.add(params.accessToken);
  }

  @override
  Future<void> signOut(SignOutParams params) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _GooglePlatform platform;
  setUp(() {
    final original = GoogleSignInPlatform.instance;
    platform = _GooglePlatform();
    GoogleSignInPlatform.instance = platform;
    addTearDown(() => GoogleSignInPlatform.instance = original);
  });

  test(
    'cold start pins saved account and requests Drive without any login UI',
    () async {
      final service = GoogleSignInAccountService(
        readStoredAccount: () => 'saved@example.com',
      );
      expect(await service.restore(), 'saved@example.com');
      expect(platform.requests, isEmpty);
      final access = await service.drive();
      access.close();
      final request = platform.requests.single;
      expect(request.email, 'saved@example.com');
      expect(request.scopes, driveScopes);
      expect(request.promptIfUnauthorized, isFalse);
      expect(platform.lightweightCalls, 0);
      expect(platform.interactiveCalls, 0);
      await access.expire();
      expect(platform.cleared, ['drive-token']);
    },
  );

  test(
    'revoked permission returns unauthorized without prompting or fallback',
    () async {
      platform.token = null;
      final service = GoogleSignInAccountService(
        readStoredAccount: () => 'saved@example.com',
      );
      await expectLater(
        service.drive(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.failure,
            'failure',
            SyncFailure.unauthorized,
          ),
        ),
      );
      expect(platform.requests.single.email, 'saved@example.com');
      expect(platform.requests.single.promptIfUnauthorized, isFalse);
      expect(platform.lightweightCalls + platform.interactiveCalls, 0);
    },
  );

  test('transient SDK failure does not request another sign-in', () async {
    final service = GoogleSignInAccountService(
      readStoredAccount: () => 'saved@example.com',
    );
    platform.failure = const GoogleSignInException(
      code: GoogleSignInExceptionCode.unknownError,
    );
    await expectLater(
      service.drive(),
      throwsA(
        isA<SyncException>().having(
          (e) => e.failure,
          'failure',
          SyncFailure.failed,
        ),
      ),
    );
    expect(platform.requests.single.promptIfUnauthorized, isFalse);
  });

  test('without a saved account no Google request is made', () async {
    final service = GoogleSignInAccountService(readStoredAccount: () => null);
    expect(await service.restore(), isNull);
    await expectLater(service.drive(), throwsA(isA<SyncException>()));
    expect(platform.requests, isEmpty);
    expect(platform.lightweightCalls + platform.interactiveCalls, 0);
  });

  test(
    'explicit sign-in can prompt and subsequent Drive access pins selection',
    () async {
      final service = GoogleSignInAccountService(
        readStoredAccount: () => 'old@example.com',
      );
      expect(await service.signIn(), 'selected@example.com');
      expect(platform.interactiveCalls, 1);
      expect(platform.requests.single.promptIfUnauthorized, isTrue);
      final access = await service.drive();
      access.close();
      expect(platform.requests.last.email, 'selected@example.com');
      expect(platform.requests.last.promptIfUnauthorized, isFalse);
    },
  );

  test(
    'signing out rejects a pending token from the previous session',
    () async {
      String? saved = 'saved@example.com';
      final service = GoogleSignInAccountService(
        readStoredAccount: () => saved,
      );
      platform.pending = Completer<ClientAuthorizationTokenData?>();
      final pendingAccess = service.drive();
      final assertion = expectLater(
        pendingAccess,
        throwsA(isA<SyncException>()),
      );
      await pumpEventQueue();
      await service.signOut();
      saved = null;
      platform.pending!.complete(
        const ClientAuthorizationTokenData(accessToken: 'stale-token'),
      );
      await assertion;
      expect(await service.restore(), isNull);
    },
  );
}
