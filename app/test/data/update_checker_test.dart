import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/sync/sync_controller.dart';
import 'package:framebook/data/update_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeSource implements UpdateSource {
  int calls = 0;
  String version = 'v0.8.0';
  bool fail = false;
  @override
  Future<UpdateRelease?> latest() async {
    calls++;
    if (fail) throw StateError('offline');
    return UpdateRelease(
      version,
      Uri.parse(
        'https://github.com/tiltozavr2545/Framebook/releases/tag/$version',
      ),
    );
  }
}

void main() {
  test('GitHub response accepts only stable release pages', () async {
    final good = GithubUpdateSource(
      MockClient(
        (_) async => http.Response(
          '{"tag_name":"v0.8.0","html_url":"https://github.com/tiltozavr2545/Framebook/releases/tag/v0.8.0","draft":false,"prerelease":false}',
          200,
        ),
      ),
    );
    expect((await good.latest())!.version, 'v0.8.0');
    final bad = GithubUpdateSource(
      MockClient(
        (_) async => http.Response(
          '{"tag_name":"v0.8.0","html_url":"https://evil.example/","draft":false,"prerelease":false}',
          200,
        ),
      ),
    );
    await expectLater(bad.latest(), throwsFormatException);
  });

  test(
    'throttles automatic checks, manual checks bypass and dismissal persists until a newer release',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final source = FakeSource();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appVersionProvider.overrideWithValue('0.7.0+9'),
          updateChecksEnabledProvider.overrideWithValue(false),
          updateSourceProvider.overrideWithValue(source),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(updateControllerProvider.notifier);
      expect(await controller.check(), UpdateResult.available);
      expect(source.calls, 1);
      await controller.dismiss();
      await controller.check();
      expect(source.calls, 1);
      expect(await controller.check(manual: true), UpdateResult.available);
      expect(container.read(updateControllerProvider), isNull);
      source.version = 'v0.9.0';
      expect(await controller.check(manual: true), UpdateResult.available);
      expect(container.read(updateControllerProvider)!.version, 'v0.9.0');
      source.fail = true;
      expect(await controller.check(manual: true), UpdateResult.failed);
    },
  );
}
