import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../app/preferences.dart';
import 'sync/sync_controller.dart';
import 'update_version.dart';

final class UpdateRelease {
  const UpdateRelease(this.version, this.url);
  final String version;
  final Uri url;
}

abstract interface class UpdateSource {
  Future<UpdateRelease?> latest();
}

final class GithubUpdateSource implements UpdateSource {
  GithubUpdateSource(this.client);
  final http.Client client;

  @override
  Future<UpdateRelease?> latest() async {
    final response = await client
        .get(
          Uri.https(
            'api.github.com',
            '/repos/tiltozavr2545/Framebook/releases/latest',
          ),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw const FormatException('Release request failed');
    }
    final data = jsonDecode(response.body);
    if (data is! Map ||
        data['tag_name'] is! String ||
        data['html_url'] is! String ||
        data['draft'] != false ||
        data['prerelease'] != false) {
      throw const FormatException('Invalid release');
    }
    final tag = data['tag_name'] as String;
    final uri = Uri.tryParse(data['html_url'] as String);
    if (UpdateVersion.parse(tag) == null ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'github.com' ||
        !uri.path.startsWith('/tiltozavr2545/Framebook/releases/tag/')) {
      throw const FormatException('Invalid release');
    }
    return UpdateRelease(tag, uri);
  }
}

final updateChecksEnabledProvider = Provider<bool>((ref) => true);

final updateSourceProvider = Provider<UpdateSource>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return GithubUpdateSource(client);
});

enum UpdateResult { available, current, failed }

class UpdateController extends Notifier<UpdateRelease?> {
  static const _checked = 'update_last_check';
  static const _dismissed = 'update_dismissed';
  Future<UpdateResult>? _running;
  UpdateRelease? lastRelease;
  static const _cachedVersion = 'update_cached_version';
  static const _cachedUrl = 'update_cached_url';

  @override
  UpdateRelease? build() {
    if (ref.read(updateChecksEnabledProvider)) {
      scheduleMicrotask(() {
        if (ref.mounted) unawaited(check());
      });
    }
    final prefs = ref.read(sharedPreferencesProvider);
    final tag = prefs.getString(_cachedVersion);
    final url = Uri.tryParse(prefs.getString(_cachedUrl) ?? '');
    final installed = UpdateVersion.parse(ref.read(appVersionProvider));
    final version = UpdateVersion.parse(tag ?? '');
    final dismissed = UpdateVersion.parse(prefs.getString(_dismissed) ?? '');
    if (tag != null &&
        url != null &&
        url.scheme == 'https' &&
        url.host == 'github.com' &&
        url.path.startsWith('/tiltozavr2545/Framebook/releases/tag/') &&
        installed != null &&
        version != null &&
        version.compareTo(installed) > 0) {
      lastRelease = UpdateRelease(tag, url);
      if (dismissed == null || version.compareTo(dismissed) > 0) {
        return lastRelease;
      }
    }
    return null;
  }

  Future<UpdateResult> check({bool manual = false}) {
    return _running ??= _check(manual).whenComplete(() {
      _running = null;
    });
  }

  Future<UpdateResult> _check(bool manual) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final last = prefs.getInt(_checked);
    if (!manual &&
        last != null &&
        now >= last &&
        now - last < const Duration(hours: 24).inMilliseconds) {
      return state == null ? UpdateResult.current : UpdateResult.available;
    }
    final source = ref.read(updateSourceProvider);
    final installed = UpdateVersion.parse(ref.read(appVersionProvider));
    try {
      final release = await source.latest();
      if (installed == null) throw const FormatException('Invalid app version');
      await prefs.setInt(_checked, now);
      final newer =
          release != null &&
          UpdateVersion.parse(release.version)!.compareTo(installed) > 0;
      if (!ref.mounted) return UpdateResult.failed;
      if (!newer) {
        lastRelease = null;
        await prefs.remove(_cachedVersion);
        await prefs.remove(_cachedUrl);
        if (!ref.mounted) return UpdateResult.current;
        state = null;
        return UpdateResult.current;
      }
      lastRelease = release;
      await prefs.setString(_cachedVersion, release.version);
      await prefs.setString(_cachedUrl, release.url.toString());
      if (!ref.mounted) return UpdateResult.available;
      final dismissed = UpdateVersion.parse(prefs.getString(_dismissed) ?? '');
      if (dismissed == null ||
          UpdateVersion.parse(release.version)!.compareTo(dismissed) > 0) {
        state = release;
      } else {
        state = null;
      }
      return UpdateResult.available;
    } catch (_) {
      return UpdateResult.failed;
    }
  }

  Future<void> dismiss() async {
    final release = state;
    if (release == null) return;
    state = null;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_dismissed, release.version);
  }
}

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateRelease?>(UpdateController.new);
